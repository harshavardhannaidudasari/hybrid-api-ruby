require 'spec_helper'

# Third real, independent verified target - an HTTP echo service, chosen to
# directly prove each verb (get/post/put/delete) sends what ApiClient claims
# it sends: the response reflects the exact query params / JSON body back.
# Originally scoped against httpbin.org (also from the public-apis list),
# substituted for postman-echo.com after httpbin.org's public instance was
# found genuinely returning 503 Service Unavailable when checked live before
# writing this spec - see README "Why postman-echo.com, not httpbin.org".
RSpec.describe 'Postman Echo API' do
  let(:client) { HybridApi::ApiClient.new(base_url: 'https://postman-echo.com') }

  it 'echoes query params back on get' do
    result = client.get('/get', { foo: 'bar' })

    expect(result.status).to eq(200)
    expect(result.json['args']['foo']).to eq('bar')
  end

  it 'echoes the json body back on post' do
    result = client.post('/post', { name: 'hybrid-api' })

    expect(result.status).to eq(200)
    expect(result.json['json']['name']).to eq('hybrid-api')
  end

  it 'echoes the json body back on put' do
    result = client.put('/put', { name: 'updated' })

    expect(result.status).to eq(200)
    expect(result.json['json']['name']).to eq('updated')
  end

  it 'succeeds on delete' do
    result = client.delete('/delete')

    expect(result.status).to eq(200)
  end
end
