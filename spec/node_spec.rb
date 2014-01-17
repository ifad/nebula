require 'spec_helper'

describe Nebula::Node do
  describe 'table' do
    it { expects(Nebula::Node.table).to eq(:nodes) }
  end

  describe 'new' do
    subject { Nebula::Node.new(label: :hello, data: { a: 'world', b: '!' }) }

    it { expects(subject.id).to eq(nil) }
    it { expects(subject.label).to eq('hello') }
    it { expects(subject.data).to eq('a' => 'world', 'b' => '!') }
  end

  describe 'create' do
    subject { Nebula::Node.create(label: :hello, data: { a: 'world', b: '!' }) }

    it { expects(subject.id).to be_kind_of(Integer) }
    it { expects(subject.label).to eq('hello') }
    it { expects(subject.data).to eq('a' => 'world', 'b' => '!') }
  end

  describe 'find' do
    let(:node) { Nebula::Node.create(label: :hello, data: { a: 'world', b: '!' }) }

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
