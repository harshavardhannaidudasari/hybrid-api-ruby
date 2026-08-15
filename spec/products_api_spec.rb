require 'spec_helper'

RSpec.describe 'Products API' do
  let(:client) { HybridApi::ApiClient.new }

  it 'gets a single product with the expected fields' do
    result = client.get('/products/1')

    expect(result.status).to eq(200)
    expect(result.json['id']).to eq(1)
    expect(result.json['title']).not_to be_empty
  end

  it 'respects the limit query param on the product list' do
    result = client.get('/products', { limit: 5 })

    expect(result.status).to eq(200)
    expect(result.json['products'].length).to eq(5)
  end

  it 'adds a product and echoes back the title with a new id' do
    result = client.post('/products/add', { title: 'hybrid-api test product' })

    expect(result.status).to eq(201)
    expect(result.json['id']).to be > 0
    expect(result.json['title']).to eq('hybrid-api test product')
  end

  it 'updates a product and returns the updated title' do
    result = client.put('/products/1', { title: 'hybrid-api updated title' })

    expect(result.status).to eq(200)
    expect(result.json['title']).to eq('hybrid-api updated title')
  end

  it 'deletes a product and marks isDeleted true' do
    result = client.delete('/products/1')

    expect(result.status).to eq(200)
    expect(result.json['isDeleted']).to eq(true)
  end
end
