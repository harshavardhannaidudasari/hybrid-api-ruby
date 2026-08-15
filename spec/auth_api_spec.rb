require 'spec_helper'

# Proves ApiClient's bearer-token support end to end: log in for a real JWT,
# then use it on a follow-up request to a protected endpoint. This is the
# flow a UI project would reuse to seed/verify account state via the API
# instead of driving the browser through a login form just for test setup.
RSpec.describe 'Auth API' do
  let(:client) { HybridApi::ApiClient.new }

  it 'rejects /auth/me with no token' do
    result = client.get('/auth/me')

    expect(result.status).to eq(401)
  end

  it 'logs in then fetches the authenticated user with the returned token' do
    login = client.post('/auth/login', {
      username: HybridApi::Config.auth_username,
      password: HybridApi::Config.auth_password
    })

    expect(login.status).to eq(200)
    token = login.json['accessToken']
    expect(token).not_to be_nil
    expect(token).not_to be_empty

    authed_client = HybridApi::ApiClient.new.with_bearer_token(token)
    me = authed_client.get('/auth/me')

    expect(me.status).to eq(200)
    expect(me.json['username']).to eq(HybridApi::Config.auth_username)
  end
end
