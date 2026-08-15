require 'spec_helper'

# Second real, independent verified target (alongside dummyjson.com) proving
# ApiClient genuinely works against any REST API via base_url: - no framework
# changes were needed to add this, only a new spec file. jsonplaceholder.typicode.com
# is built for the exact same purpose as dummyjson.com ("fake REST API for
# testing and prototyping"), sourced from the public-apis list
# (github.com/public-apis/public-apis).
RSpec.describe 'JSONPlaceholder API' do
  let(:client) { HybridApi::ApiClient.new(base_url: 'https://jsonplaceholder.typicode.com') }

  it 'gets a single post with the expected fields' do
    result = client.get('/posts/1')

    expect(result.status).to eq(200)
    expect(result.json['id']).to eq(1)
    expect(result.json['title']).not_to be_empty
  end

  it 'respects the _limit query param on the post list' do
    result = client.get('/posts', { _limit: 5 })

    expect(result.status).to eq(200)
    expect(result.json.length).to eq(5)
  end

  it 'adds a post and echoes back the title with a new id' do
    result = client.post('/posts', { title: 'hybrid-api test', body: 'testing', userId: 1 })

    expect(result.status).to eq(201)
    expect(result.json['id']).to be > 0
    expect(result.json['title']).to eq('hybrid-api test')
  end

  it 'updates a post and returns the updated title' do
    result = client.put('/posts/1', { id: 1, title: 'updated title', body: 'updated', userId: 1 })

    expect(result.status).to eq(200)
    expect(result.json['title']).to eq('updated title')
  end

  it 'deletes a post successfully' do
    result = client.delete('/posts/1')

    expect(result.status).to eq(200)
  end
end
