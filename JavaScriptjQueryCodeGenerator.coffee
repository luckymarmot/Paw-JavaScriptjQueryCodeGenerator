require "mustache.js"
require "URI.js"

addslashes = (str) ->
    ("#{str}").replace(/[\\"]/g, '\\$&')

JavaScriptjQueryCodeGenerator = ->

    @url = (request) ->
        url_params_object = (() ->
            _uri = URI request.url
            _uri.search true
        )()
        url_params = ({
            "name": addslashes name
            "value": addslashes value
        } for name, value of url_params_object)

        return {
            "base": addslashes (() ->
                _uri = URI request.url
                _uri.search("")
                _uri
            )()
            "params": url_params
            "has_params": url_params.length > 0
        }

    @headers = (request) ->
        headers = request.headers
        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": addslashes header_name
                "header_value": addslashes header_value
            } for header_name, header_value of headers)
        }

    @body = (request) ->
        json_body = request.jsonBody
        if json_body
            return {
                "has_body":true
                "has_json_body":true
                "json_body_object":@json_body_object json_body, 0
            }

        url_encoded_body = request.urlEncodedBody
        if url_encoded_body
            return {
                "has_body":true
                "has_url_encoded_body":true
                "url_encoded_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of url_encoded_body)
            }

        multipart_body = request.multipartBody
        if multipart_body
            return {
                "has_body":true
                "has_multipart_body":true
                "multipart_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of multipart_body)
            }

        raw_body = request.body
        if raw_body
            if raw_body.length < 5000
                return {
                    "has_body":true
                    "has_raw_body":true
                    "raw_body": addslashes raw_body
                }
            else
                return {
                    "has_body":true
                    "has_long_body":true
                }

        return {
            "has_body":false
        }

    @json_body_object = (object, indent = 0) ->
        if object == null
            s = "null"
        else if typeof(object) == 'string'
            s = "\"#{addslashes object}\""
        else if typeof(object) == 'number'
            s = "#{object}"
        else if typeof(object) == 'boolean'
            s = "#{if object then "true" else "false"}"
        else if typeof(object) == 'object'
            indent_str = Array(indent + 2).join('    ')
            indent_str_children = Array(indent + 3).join('    ')
            if object.length?
                s = "[\n" +
                    ("#{indent_str_children}#{@json_body_object(value, indent+1)}" for value in object).join(',\n') +
                    "\n#{indent_str}]"
            else
                s = "{\n" +
                    ("#{indent_str_children}\"#{addslashes key}\": #{@json_body_object(value, indent+1)}" for key, value of object).join(',\n') +
                    "\n#{indent_str}}"

        return s

    @generate = (context) ->
        request = context.getCurrentRequest()
        method = request.method.toUpperCase()

        view =
            "request": context.getCurrentRequest()
            "url": @url request
            "method": method
            "headers": @headers request
            "body": @body request
            "has_content": method != 'GET' and method != 'HEAD'

        # convenience variable
        view.has_content_and_url_params = view.has_content && view.url.has_params

        # if not has_content, just remove the body
        if not view.has_content
            view.body = null

        template = readFile "javascript.mustache"
        Mustache.render template, view

    return


JavaScriptjQueryCodeGenerator.identifier =
    "com.luckymarmot.PawExtensions.JavaScriptjQueryCodeGenerator"
JavaScriptjQueryCodeGenerator.title =
    "JavaScript (jQuery)"
JavaScriptjQueryCodeGenerator.fileExtension = "js"
JavaScriptjQueryCodeGenerator.languageHighlighter = "javascript"

registerCodeGenerator JavaScriptjQueryCodeGenerator
