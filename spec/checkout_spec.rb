require "rails_helper"
require "#{Rails.root}/lib/checkout"

def populate_tickets(event_id, count: 1)
  count.times do
    Ticket.create!(event_id: event_id)
  end
end

describe Checkout do
  describe "#process" do
    let(:user) { User.create!(balance_in_cents: 100) }
    let(:event) { Event.create!(name: "Rails meetup", price_in_cents: 100) }

    context "when there is a single ticket" do
      it "processes the checkout" do
        populate_tickets(event.id)
        checkout = described_class.new(user_id: user.id, event_id: event.id)

        checkout.process

        user.reload
        purchased_tickets = Ticket.where(event_id: event.id, user_id: user.id)

        expect(purchased_tickets.count).to eq(1)
        expect(user.balance_in_cents).to eq(0)
      end
    end

    context "when there are no available tickets" do
      it "raises an error" do
        checkout = described_class.new(user_id: user.id, event_id: event.id)

        expect { checkout.process }.to raise_error("There are no available tickets for this event :(")
      end
    end

    context "when the user does not have enough balance to buy the ticket" do
      it "raises an error" do
        user.update_column(:balance_in_cents, 0)
        populate_tickets(event.id)

        checkout = described_class.new(user_id: user.id, event_id: event.id)

        expect { checkout.process }.to raise_error("User does not have enough balance for this event :(")
      end
    end
  end

  describe "calling #process twice" do
    let(:user) { User.create!(balance_in_cents: 100) }
    let(:event) { Event.create!(name: "Rails meetup", price_in_cents: 100) }

    context "when there are 2 tickets available, but the user does not have enough balance" do
      it "raises an error, bills the user once, and leaves the ticket available" do
        populate_tickets(event.id, count: 2)
        checkout = described_class.new(user_id: user.id, event_id: event.id)

        checkout.process
        expect { checkout.process }.to raise_error("User does not have enough balance for this event :(")
        user.reload

        available_tickets = Ticket.where(user_id: nil)
        purchased_tickets = Ticket.where(user_id: user.id)

        expect(user.balance_in_cents).to eq(0)
        expect(available_tickets.count).to eq(1)
        expect(purchased_tickets.count).to eq(1)
      end
    end

    context "when there is a single ticket available" do
      it "raises an error and bills the user once" do
        populate_tickets(event.id)
        checkout = described_class.new(user_id: user.id, event_id: event.id)

        checkout.process
        expect { checkout.process }.to raise_error("There are no available tickets for this event :(")

        user.reload
        purchased_tickets = Ticket.where(event_id: event.id, user_id: user.id)

        expect(purchased_tickets.count).to eq(1)
        expect(user.balance_in_cents).to eq(0)
      end
    end
  end

  describe "concurrent calls to #process" do
    let(:user) { User.create!(balance_in_cents: 100) }
    let(:event) { Event.create!(name: "Rails meetup", price_in_cents: 100) }

    context "when 2 tickets exist" do
      it "only assigns one ticket to the user" do
        populate_tickets(event.id, count: 2)
        user # create user

        ActiveRecord::Base.connection.disconnect!
        Array.new(50) do
          Process.fork do
            $stderr.reopen(File.new(File::NULL, "w"))
            $stdout.reopen(File.new(File::NULL, "w"))
            ActiveRecord::Base.establish_connection
            checkout = described_class.new(user_id: user.id, event_id: event.id)
            checkout.process
          end
        end
        ActiveRecord::Base.establish_connection

        user.reload
        available_tickets = Ticket.where(user_id: nil)
        purchased_tickets = Ticket.where(user_id: user.id)

        expect(available_tickets.count).to eq(1)
        expect(purchased_tickets.count).to eq(1)
        expect(user.balance_in_cents).to eq(0)
      end
    end
  end
end