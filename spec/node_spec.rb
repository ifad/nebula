require 'spec_helper'

describe Nebula::Node do
  def create
  end

  describe 'table' do
    it { expects(Nebula::Node.table).to eq(:nodes) }
  end

  describe 'create' do
    subject { Nebula::Node.create(:hello, data: { a: 'world', b: '!' }) }

    it { expects(subject.id).to be_kind_of(Integer) }
    it { expects(subject.label).to eq('hello') }
    it { expects(subject.data).to eq('a' => 'world', 'b' => '!') }
  end
end
