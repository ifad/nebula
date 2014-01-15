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

  describe 'find' do
    let(:node) { Nebula::Node.create(:hello, data: { a: 'world', b: '!' }) }

    describe 'existing' do
      subject { Nebula::Node.find(node.id) }

      it { expects(subject).to eq(node) }
    end

    describe 'non existing' do
      subject { Nebula::Node.find(node.id + 1) }

      it { expects(subject).to eq(nil) }
    end
  end
end
