require "rails_helper"

class BookingConfirmed < RailsEventStore::Event
end

class BookingCanceled < RailsEventStore::Event
end

class Booking
  def initialize
    self.id = SecureRandom.hex
  end

  def confirm
    events = load_events_for_booking
    self.state = build_state(events)

    raise StandardError, 'Booking cannot be confirmed' unless can_be_confirmed?

    client.publish(BookingConfirmed.new(data: {}), stream_name: stream_name)
  end

  def cancel
    client.publish(BookingCanceled.new(data: {}), stream_name: stream_name)
  end

  private

  attr_accessor :id, :state

  def can_be_confirmed?
    state.inquiry?
  end

  def stream_name
    "booking-#{id}"
  end

  def load_events_for_booking
    client.read.stream(stream_name).to_a
  end

  def client
    @client ||= RailsEventStore::Client.new
  end
  
  def build_state(events)
    result = 'inquiry'

    events.each do |event|
      if event.is_a?(BookingConfirmed)
        result = 'confirmed'
      elsif event.is_a?(BookingCanceled)
        result = 'canceled'
      end
    end

    ActiveSupport::StringInquirer.new(result)
  end
end

RSpec.describe Booking do
  describe '#confirm' do
    it "confirms the booking" do
      booking = Booking.new

      booking.confirm

      expect(event_store).to have_published(an_event(BookingConfirmed))
    end

    it "raises an error when booking is confirmed twice" do
      booking = Booking.new

      booking.confirm

      expect { booking.confirm }.to raise_error(StandardError, 'Booking cannot be confirmed')
    end

    context 'when already canceled' do
      it 'cannot be confirmed' do
        booking = Booking.new

        booking.cancel

        expect { booking.confirm }.to raise_error(StandardError, 'Booking cannot be confirmed')
      end
    end
  end

  def event_store
    Rails.configuration.event_store
  end
end
