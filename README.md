# Kong Middleman advanced

A Kong plugin that enables an extra HTTP POST request before proxying the original.

based on https://github.com/pantsel/kong-middleman-plugin and https://github.com/mdemou/kong-middleman

list of change :
- Update for kong v2
- move json.lua to https://github.com/rxi/json.lua
- Update schema for v2
	- add config for include certificate (default false)
    - add config for include credential (default false)
    - add config for include route (default false)
 - change payload :
 	- add certificate (resty_kong_tls.get_full_client_certificate_chain())
    - add credential (kong.client.get_credential())
    - add route (kong.router.get_route() and kong.router.get_service())
    - rename uri_args to params
    - rename body data to body
    - no json.encode if headers["content-type"] == 'application/json'
    - move body, headers and params in request field


payload :
```lua
 local payload_body = [[{"certificate":]] .. raw_cert .. [[,"credential":]] .. raw_credential ..  [[,"kong_routing":]] .. raw_kong_routing .. [[,"request": {"headers":]] .. raw_json_headers .. [[,"params":]] .. raw_json_uri_args .. [[,"body":]] .. raw_json_body_data .. [[}}]]
 ```

roadmap:
- change config for list of service


## Description

In some cases, you may need to validate a request to a separate server or service using custom logic before Kong proxies it to your API.
Middleman enables you to do that by allowing you to make an extra HTTP request before calling an API endpoint.


# NEXT WIP

## Installation

WIP

## Configuration

You can add the plugin on top of an API by executing the following request on your Kong server:

<pre>
$ curl -X POST http://kong:8001/apis/{api}/plugins \
    --data "name=middleman-advanced" \
    --data "config.url=http://myserver.io/validate"
    --data "config.response=table"
    --data "config.timeout=10000"
    --data "config.keepalive=60000"
</pre>

<table><thead>
<tr>
<th>form parameter</th>
<th>default</th>
<th>description</th>
</tr>
</thead><tbody>
<tr>
<td><code>name</code></td>
<td></td>
<td>The name of the plugin to use, in this case: <code>middleman</code></td>
</tr>
<tr>
<td><code>config.url</code><br><em>required</em></td>
<td></td>
<td>The URL to which the plugin will make a JSON <code>POST</code> request before proxying the original request.</td>
</tr>
<tr>
<td><code>config.response</code><br><em>required</em></td>
<td></td>
<td>The type of response the middleman service is going to respond with</td>
</tr>
<tr>
<td><code>config.timeout</code></td>
<td></td>
<td>Timeout (miliseconds) for the request to the URL specified above. Default value is 10000.</td>
</tr>
<tr>
<td><code>config.keepalive</code></td>
<td></td>
<td>Keepalive time (miliseconds) for the request to the URL specified above. Default value is 60000.</td>
</tr>
</tbody></table>

Middleman will execute a JSON <code>POST</code> request to the specified <code>url</code> with the following body:

<table>
    <tr>
        <th>Attribute</th>
        <th>Description</th>
    </tr>
    <tr>
    <td><code>body_data</code></td>
    <td><small>The body of the original request</small></td>
    </tr>
    <tr>
        <td><code>url_args</code></td>
        <td><small>The url arguments of the original request</small></td>
    </tr>
    <tr>
        <td><code>headers</code></td>
        <td><small>The headers of the original request</small></td>
    </tr>
</table>

In the scope of your own endpoint, you may validate any of these attributes and accept or reject the request according to your needs. If an HTTP response code of 299 or less is returned, the request is accepted. Any response code above 299 will cause the request to be rejected.  

## Author
Panagis Tselentis

## License
<pre>
The MIT License (MIT)
=====================

Copyright (c) 2020 David TOUZET

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</pre>
