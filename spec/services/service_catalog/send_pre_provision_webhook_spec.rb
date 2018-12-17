describe ServiceCatalog::SendPreProvisionWebhook do
  include ServiceSpecHelper

  let(:post_wh) { instance_double("ServiceCatalog::PostWebhook") }

  let(:service_offering_ref) { "999" }
  let(:service_plan_ref) { "777" }
  let(:order) { create(:order) }
  let(:hook_parameters) do
    { :url => 'https://www.example.com' }
  end

  let(:portfolio_item_id) { portfolio_item.id }
  let(:webhook) { create(:webhook, hook_parameters) }
  let!(:order_item) do
    create(:order_item, :portfolio_item_id           => portfolio_item_id,
                        :order_id                    => order.id,
                        :service_plan_ref            => service_plan_ref,
                        :service_parameters          => { 'b' => 1 },
                        :provider_control_parameters => { 'a' => 1 },
                        :count                       => 1)
  end
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref     => service_offering_ref,
                            :pre_provision_webhook_id => webhook.id)
  end
  let(:portfolio_item_id) { portfolio_item.id.to_s }
  let(:params) do
    order_item.id.to_s
  end

  let(:sppw) { ServiceCatalog::SendPreProvisionWebhook.new(params) }

  context "#process" do
    it "sucess" do
      allow(ServiceCatalog::PostWebhook).to receive(:new).and_return(post_wh)
      allow(post_wh).to receive(:process) do |json_body|
        body = JSON.parse(json_body)
        expect(body['title']).to eq(described_class::TITLE)
        expect(body['description']).to eq(portfolio_item.name)
      end.and_return(200)

      expect(sppw.process).to eq(200)
    end

    it "raises exception" do
      allow(ServiceCatalog::PostWebhook).to receive(:new).and_return(post_wh)
      allow(post_wh).to receive(:process).and_raise("Kaboom")

      expect { sppw.process }.to raise_error(StandardError)
    end

    context "no webhook defined" do
      let(:portfolio_item) do
        create(:portfolio_item, :service_offering_ref => service_offering_ref)
      end

      it "invalid args" do
        expect { sppw.process }.to raise_error(ArgumentError)
      end
    end

    context "no order found" do
      let(:params) do
        "999"
      end

      it "raises error" do
        expect { sppw.process }.to raise_error(StandardError)
      end
    end

    context "portfolio item not found" do
      let(:portfolio_item_id) { "999" }
      it "raises error" do
        expect { sppw.process }.to raise_error(StandardError)
      end
    end
  end
end
