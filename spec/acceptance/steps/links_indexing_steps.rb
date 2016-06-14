step 'I create a draft content item' do
  @content_id = SecureRandom.uuid
  @base_path = "/" + SecureRandom.hex

  payload = {
    title: 'Hallo',
    base_path: @base_path,
    schema_name: 'detailed_guide',
    document_type: 'detailed_guide',
    publishing_app: 'end-to-end-publishing-test',
    rendering_app: 'end-to-end-publishing-test',
    locale: 'en',
    routes: [
      { path: @base_path, type: 'exact' }
    ]
  }

  Services.publishing_api.put_content(@content_id, payload)

  sleep 0.1
end

step "it should not be in the live content store" do
  content_item = Services.content_store.content_item(@base_path)
  expect(content_item).to eql(nil)
end

step "it should be in the draft content store" do
  draft_content_item = Services.draft_content_store.content_item(@base_path)
  expect(draft_content_item['content_id']).to eql(@content_id)
end

step "we publish the item" do
  Services.publishing_api.publish(@content_id, 'major')
  sleep 0.1
end

step "we should see it in the live content store" do
  live_content_item = Services.content_store.content_item(@base_path)
  expect(live_content_item['content_id']).to eql(@content_id)
end

step "we send the document to search" do
  rummager_payload = {
    title: SecureRandom.hex,
    format: 'edition',
    description: 'What',
    indexable_content: 'whasdjhasd',
    link: @base_path
  }

  Services.rummager.add_document('edition', @base_path, rummager_payload)
end

step "we wait until the document is indexed" do
  Timeout::timeout(60) do
    while true do
      begin
        Services.rummager.get_content!(@base_path)
        break
      rescue GdsApi::HTTPNotFound
        print "."
        sleep 0.2
      end
    end
  end
end

step "we create a topic to tag to" do
  @topic_content_id = SecureRandom.uuid
  @topic_slug = SecureRandom.hex

  topic_base_path = '/topic/' + @topic_slug

  topic_payload = {
    title: 'Hallo',
    base_path: topic_base_path,
    schema_name: 'topic',
    document_type: 'topic',
    publishing_app: 'end-to-end-publishing-test',
    rendering_app: 'end-to-end-publishing-test',
    locale: 'en',
    routes: [
      { path: topic_base_path, type: 'exact' }
    ]
  }

  Services.publishing_api.put_content(@topic_content_id, topic_payload)
  Services.publishing_api.publish(@topic_content_id, 'major')
end

step "we tag our document to this topic" do
  Services.publishing_api.patch_links(
    @content_id,
    links: {
      topics: [@topic_content_id]
    }
  )

  sleep 0.5
end

step "both content stores have been updated with `organisations` tag" do
  item = Services.content_store.content_item(@base_path)
  expect(item['links']['topics'].first['content_id']).to eql(@topic_content_id)

  draft_item = Services.content_store.content_item(@base_path)
  expect(draft_item['links']['topics'].first['content_id']).to eql(@topic_content_id)
end

step "and the document is updated in search" do
  rummager_document = Services.rummager.get_content!(@base_path)
  expect(rummager_document['raw_source']['specialist_sectors']).to eventually_equal([@topic_slug])
end
