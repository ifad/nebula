require 'spec_helper'

describe Nebula::Node do
  describe '::table' do
    it { expects(Nebula::Node.table).to eq(:nodes) }
  end

  describe '::new' do
    subject { Nebula::Node.new(label: :hello, data: { a: 'world', b: '!' }) }

    it { expects(subject.id).to eq(nil) }
    it { expects(subject.label).to eq('hello') }
    it { expects(subject.data).to eq('a' => 'world', 'b' => '!') }
  end

  describe '::create' do
    subject { Nebula::Node.create(label: :hello, data: { a: 'world', b: '!' }) }

    it { expects { subject }.to change(Nebula::Node, :count).by(1) }
    it { expects(subject.id).to be_kind_of(Integer) }
    it { expects(subject.label).to eq('hello') }
    it { expects(subject.data).to eq('a' => 'world', 'b' => '!') }
  end

  describe '::find' do
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

  describe '::count' do
    let!(:nodes) do
      3.times.map do
        Nebula::Node.create(label: :hello, data: { a: 'world', b: '!' })
      end
    end

    it { expects(Nebula::Node.count).to eq(3) }
  end

  describe '::destroy_all' do
    let!(:nodes) do
      3.times.map do
        Nebula::Node.create(label: :hello, data: { a: 'world', b: '!' })
      end
    end

    it { expects { Nebula::Node.destroy_all }.to change(Nebula::Node, :count) }
  end

  describe '::index_names' do
    subject { Nebula::Node.index_names }
    it { expects(subject).to match_array(%w{ index_on_nebula_nodes_label nebula_nodes_pkey }) }
  end

  describe '::create_index' do
    describe 'without name' do
      subject { Nebula::Node.create_index(on: :a) }
      it { expects(subject).to be_true }
      it { expects { subject }.to change { Nebula::Node.indexes.length }.by(1) }
    end

    describe 'with name' do
      subject! { Nebula::Node.create_index(on: :a, name: 'index_on_a') }
      it { expects(subject).to be_true }
      it { expects(Nebula::Node.index_names).to include('nebula_nodes_index_on_a') }
    end

    describe 'with type' do
      subject { Nebula::Node.create_index(on: :a, type: :hash) }
      it { expects(subject).to be_true }
    end

    describe 'with multiple keys' do
      subject { Nebula::Node.create_index(on: [ :a, :b ]) }
      it { expects(subject).to be_true }
    end

    describe 'with illegal type' do
      subject { Nebula::Node.create_index(on: [ :a, :b ], path: false, type: :hash) }
      it { expects { subject }.to raise_error(PG::FeatureNotSupported) }
    end
  end

  describe 'save' do
    describe 'with valid attribtes' do
      describe 'with data' do
        subject { Nebula::Node.new(label: :hello, data: { a: 'world', b: '!' }) }

        it { expects { subject.save }.to change(Nebula::Node, :count).by(1) }
        it { expects(subject.save.id).to be_kind_of(Integer) }
        it { expects(subject.save.label).to eq('hello') }
        it { expects(subject.save.data).to eq('a' => 'world', 'b' => '!') }
      end

      describe 'without data' do
        subject { Nebula::Node.new(label: :hello) }

        it { expects { subject.save }.to change(Nebula::Node, :count).by(1) }
        it { expects(subject.save.id).to be_kind_of(Integer) }
        it { expects(subject.save.label).to eq('hello') }
        it { expects(subject.save.data).to eq({ }) }
      end
    end

    describe 'with invalid attributes' do
      subject { Nebula::Node.new(data: { a: 'world', b: '!' }) }
      it { expects { subject.save }.to raise_error(PG::NotNullViolation) }
    end
  end
end
