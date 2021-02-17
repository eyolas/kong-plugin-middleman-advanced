# Kong Middleman advanced

A Kong plugin that enables an extra HTTP POST requests before proxying the original.

based on https://github.com/pantsel/kong-middleman-plugin and https://github.com/mdemou/kong-middleman



## Description

In some cases, you may need to validate a request to a separate server or service using custom logic before Kong proxies it to your API.
Middleman enables you to do that by allowing you to make an extra HTTP requests before calling an API endpoint.

## Change from the original plugin

list of change :
- Update for kong v2
- move json.lua to https://github.com/rxi/json.lua
- Update schema for v2
	- add config for include certificate (default false)
    - add config for include credential (default false)
    - add config for include route (default false)
    - add config for include consumer (default false)
 - change payload :
 	- add certificate (resty_kong_tls.get_full_client_certificate_chain())
    - add credential (kong.client.get_credential())
    - add route (kong.router.get_route() and kong.router.get_service())
    - add consumer (kong.client.get_consumer())
    - rename uri_args to params
    - rename body data to body
    - no json.encode if headers["content-type"] == 'application/json'
    - move body, headers and params in request field


payload :
```lua
local payload = {
    ['certificate'] = certificate,
    ['consumer'] = consumer,
    ['credential'] = credential,
    ['kong_routing'] = kong_routing,
    ['request'] = {
      ['headers'] = headers,
      ['params'] = params,
      ['body'] = json_body,
    }
  }
```

## Installation

WIP

## Configuration

You can add the plugin on top of an API by executing the following request on your Kong server:

```sh
$ http POST :8001/services/{api}/plugins name=middleman-advanced config:='{ "services": [{"url": "http://myserver.io/validate", "response": "table", "timeout": 10000, "keepalive": 60000}]}'
```

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
<td><code>config.services</code><br><em>required</em></td>
<td></td>
<td>The list of services witch the plugin make a JSON <code>POST</code></td>
</tr>

</tbody></table><br />

### Service config
<table><thead>
<tr>
<th>form parameter</th>
<th>default</th>
<th>description</th>
</tr>
</thead><tbody>
<tr>
<td><code>url</code><br><em>required</em></td>
<td></td>
<td>The URL to which the plugin will make a JSON <code>POST</code> request before proxying the original request.</td>
</tr>
<tr>
<td><code>response</code><br><em>required</em></td>
<td>table</td>
<td>The type of response the middleman service is going to respond with</td>
</tr>
<tr>
<td><code>timeout</code></td>
<td>10000</td>
<td>Timeout (miliseconds) for the request to the URL specified above. Default value is 10000.</td>
</tr>
<tr>
<td><code>keepalive</code></td>
<td>60000</td>
<td>Keepalive time (miliseconds) for the request to the URL specified above. Default value is 60000.</td>
</tr>
<tr>
<td><code>include_cert</code></td>
<td>false</td>
<td>Include the original certificate in JSON POST</td>
</tr>
<tr>
<td><code>include_credential</code></td>
<td>false</td>
<td>Include the credential in JSON POST</td>
</tr>
<tr>
<td><code>include_consumer</code></td>
<td>false</td>
<td>Include the consumer in JSON POST</td>
</tr>
<tr>
<td><code>include_route</code></td>
<td>false</td>
<td>Include the route in JSON POST</td>
</tr>
</tbody></table>

Middleman will execute a JSON <code>POST</code> request to the specified <code>url</code> with the following body:

JSON POST
<table>
    <tr>
        <th>Attribute</th>
        <th>Description</th>
    </tr>
    <tr>
    <td><code>certificate</code></td>
    <td><small>The certificate of the original request if include_credential <br/> see resty_kong_tls.get_full_client_certificate_chain()</small></td>
    </tr>
    <tr>
        <td><code>consumer</code></td>
        <td><small>The consumer of the original request <br/> see kong.client.get_consumer()</small></td>
    </tr>
    <tr>
        <td><code>credential</code></td>
        <td><small>The consumer of the original request <br/> see kong.client.get_credential()</small></td>
    </tr>
    <tr>
        <td><code>kong_routing</code></td>
        <td><small>The kong_routing of the original request <br/> see kong.router.get_route() and kong.router.get_service()</small></td>
    </tr>
    <tr>
        <td><code>request</code></td>
        <td><small>The request of the original request <br /> see the next table : request</small></td>
    </tr>
</table>

Request
<table>
    <tr>
        <th>Attribute</th>
        <th>Description</th>
    </tr>
    <tr>
    <td><code>body</code></td>
    <td><small>The body of the original request</small></td>
    </tr>
    <tr>
        <td><code>params</code></td>
        <td><small>The url arguments of the original request</small></td>
    </tr>
    <tr>
        <td><code>headers</code></td>
        <td><small>The headers of the original request</small></td>
    </tr>
</table>

In the scope of your own endpoint, you may validate any of these attributes and accept or reject the request according to your needs. If an HTTP response code of 299 or less is returned, the request is accepted. Any response code above 299 will cause the request to be rejected.  

## Author
David TOUZET

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
