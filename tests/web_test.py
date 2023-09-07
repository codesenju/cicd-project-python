import unittest
from flask import Flask
from web import app

class FlaskTestCase(unittest.TestCase):
    def test_hello_world(self):
        tester = app.test_client(self)
        response = tester.get('/',content_type='html/text')
        self.assertEqual(response.status_code,200)
        self.assertEqual(response.data,b'Hello, World!')

    def test_health(self):
        tester = app.test_client(self)
        response = tester.get('/healthz',content_type='html/text')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, b'OK!')

if __name__ =='__main__':
    unittest.main()