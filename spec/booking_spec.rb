require "rails_helper"

class BookingConfirmed < RailsEventStore::Event
end

class Booking
  def confirm
    Rails.configuration.event_store.publish(BookingConfirmed.new(data: {}))
  end
end

RSpec.describe Booking do
  it "confirms the booking" do
    booking = Booking.new

    booking.confirm

    expect(event_store).to have_published(an_event(BookingConfirmed))
  end

  it "raises an error when booking is confirmed twice" do
    booking = Booking.new

    booking.confirm

    expect { booking.confirm }.to raise_error
  end

  def event_store
    Rails.configuration.event_store
  end
end
