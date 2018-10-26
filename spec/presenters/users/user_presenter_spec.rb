require 'spec_helper'

describe UserPresenter do
  subject { UserPresenter.new(user) }
  let(:user) { FactoryBot.build_stubbed(:user, first_name: '', last_name: '', email: '') }

  describe '#display_name' do
    it 'should display the first part of the email address when no name is given' do
      user.email = 'joe@blow.com'
      expect(subject.display_name).to eq 'joe'
    end

    it 'should display the full name when first and last name fields are given' do
      user.first_name = 'Joe'
      user.last_name = 'Blow'
      expect(subject.display_name).to eq 'Joe Blow'
    end

    it 'should display the first name when the last name field is empty' do
      user.first_name = 'Joe'
      user.last_name = ''
      expect(subject.display_name).to eq 'Joe'
    end

    it 'should ignore extra whitespaces' do
      user.first_name = ''
      user.last_name = ' Blow '
      expect(subject.display_name).to eq 'Blow'
    end

    it 'should display anonymous when there is no first name, last name or email' do
      expect(subject.display_name).to eq 'Anonymous'
    end
  end

  describe '#timezone' do
    context 'when latitude and longitude present' do
      before do
        Timezone::Lookup.config(:test)
        Timezone::Lookup.lookup.stub(34.0, -118.0, 'America/Los_Angeles')
        Timezone::Lookup.lookup.default('Europe/London')
      end
      it 'should display timezone when it can be determined' do
        user.latitude = 34.0
        user.longitude = -118.0
        expect(subject.timezone).to eq 'America/Los_Angeles'
        user.latitude = 51
        user.longitude = 0
        expect(subject.timezone).to eq 'Europe/London'
      end
    end
    context 'when no latitude and longitude present' do
      it 'should display guessed timezone' do
        user.latitude = nil
        user.longitude = nil
        user.timezone_offset = nil
        expect(subject.timezone).to eq('UTC')
        user.timezone_offset = 0
        expect(subject.timezone).to eq('Casablanca')
        user.timezone_offset = 3600
        expect(subject.timezone).to eq('Amsterdam')
      end
    end
  end

  describe '#timezone_formatted_offset' do
    before do
      Timezone::Lookup.config(:test)
      Timezone::Lookup.lookup.stub(25.95, 32.58, 'Africa/Cairo')
    end
    it 'should display timezone formatted offset when it can be determined' do
      user.latitude = 25.95
      user.longitude = 32.58
      expect(ActiveSupport::TimeZone.new(subject.timezone)).to receive(:formatted_offset).and_return('+02:00')
      expect(subject.timezone_formatted_offset).to eq '+02:00'
    end
  end

  describe '#contributors' do
    let(:user) { create(:user) }
    let(:commit_counts) { create_list(:commit_count, 2, user: user) }

    before do
      user.follow commit_counts.first.project
    end

    it 'should only return commit counts for the projects that the user follows' do
      expect(subject.contributions).to eq([commit_counts[0]])
    end
  end

  describe 'user status' do
    let(:user) { FactoryBot.create(:user) }

    before(:each) do
      @status = FactoryBot.create_list(:status, 3,
                                       status: Status::OPTIONS[rand(Status::OPTIONS.length)],
                                       user: user)
      user.reload
    end

    it 'should have a status' do
      expect(subject.status).to eq("<span>#{@status[2][:status]}</span>")
    end

    it 'status should be html_safe' do
      expect(subject.status).to be_html_safe
    end

    it 'status? should be true' do
      expect(subject.status?).to eq true
    end
  end

  describe 'empty profile fields' do
    let!(:user) { FactoryBot.create(:user) }

    it 'should return a list of all fields if they are nil' do
      user.first_name = user.last_name = user.bio = nil
      user.skill_list = nil
      user.save
      user.reload
      expect(subject.blank_fields).to eq('First name, Last name, Skills, and Bio')
    end

    it 'should return a list of all fields if they are empty' do
      user.first_name = user.last_name = user.bio = ''
      user.skill_list = ''
      user.save
      user.reload
      expect(subject.blank_fields).to eq('First name, Last name, Skills, and Bio')
    end

    it 'should return only empty fields' do
      user.last_name = user.bio = ''
      expect(subject.blank_fields).to eq('Last name and Bio')
    end
  end
end
