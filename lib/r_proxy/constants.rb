module RProxy
  module Constants
    HTTP_SUCCESS = "HTTP/1.1 200 OK\r\n\r\n"
    HTTP_FAILED_AUTH = "HTTP/1.1 401 Unauthorized\r\n\r\n"
    HTTP_BAD_REQUEST = "HTTP/1.1 400 Bad Request\r\n\r\n"

    HTTP_CONNECT_TITLE = "CONNECT\s"
  end
end