from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse, unquote
import os 

def str2bool(s):
    if type(s) == bool:
        return s
    return s.lower() in ("yes", "true", "t", "1")

port = int(os.environ.get('PORT', 8080))
basic_auth = str2bool(os.environ.get('BASIC_AUTH', False))
address = ('localhost', port)


class MyHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        s = 'path = {}'.format(self.path)
        parsed_path = urlparse(self.path)
        s = s + '\n' + 'parsed: path = {}, query = {}'.format(parsed_path.path, parse_qs(parsed_path.query))
        s = s + '\n' + 'headers\r\n-----\r\n{}-----'.format(self.headers)
        print(s)

        if basic_auth and self.headers.get('Authorization') == None:
            self.send_response(401)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('WWW-Authenticate', 'Basic realm="Demo Realm"')
            self.end_headers()
            s += "\n\n401: no auth header received\r\n"
            self.wfile.write(bytes(s, 'utf-8'))
            return


        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.end_headers()
        self.wfile.write(bytes(s, 'utf-8'))

    def do_POST(self):
        print('path = {}'.format(self.path))

        parsed_path = urlparse(self.path)
        print('parsed: path = {}, query = {}'.format(parsed_path.path, parse_qs(parsed_path.query)))

        print('headers\r\n-----\r\n{}-----'.format(self.headers))

        content_length = int(self.headers['content-length'])
        
        print('body = {}'.format(unquote(self.rfile.read(content_length).decode('utf-8'))))
        
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.end_headers()
        self.wfile.write(b'Hello from do_POST')
        

with HTTPServer(address, MyHTTPRequestHandler) as server:
	
	print('running http server on ', port)
	server.serve_forever()
