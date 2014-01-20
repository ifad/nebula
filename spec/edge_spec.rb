require 'spec_helper'

describe Nebula::Edge do

  let(:from) { Nebula::Node.create(label: :from, data: { 'foo' => 'bar' }) }
  let(:to)   { Nebula::Node.create(label: :to,   data: { 'bar' => 'baz' }) }

  describe '::table' do
    it { expects(Nebula::Edge.table).to eq(:edges) }
  end

  describe '::new' do
    subject { Nebula::Edge.new(:label => 123, :from_node_id => '1', :to_node_id => 2) }

    it { expects(subject.id).to eq(nil) }
    it { expects(subject.label).to eq('123') }
    it { expects(subject.from_node_id).to eq(1) }
    it { expects(subject.to_node_id).to eq(2) }
  end

  describe '::create' do
    describe 'with invalid node ids' do
      subject { Nebula::Edge.create(:label => 'hello', :from_node_id => '1', :to_node_id => 2) }
      it { expects { subject }.to raise_error(PG::ForeignKeyViolation) }
    end

    describe 'with valid node ids' do
      subject { Nebula::Edge.create(label: 'hello', from: from, to: to) }

      it { expects(subject.id).to be_kind_of(Integer) }
      it { expects(subject.label).to eq('hello') }
      it { expects(subject.from_node_id).to eq(from.id) }
      it { expects(subject.to_node_id).to eq(to.id) }
    end
  end

  describe '::find' do
    let(:edge) { Nebula::Edge.create(label: :hello, from: from, to: to) }

    describe 'existing' do
      subject { Nebula::Edge.find(edge.id) }
      it { expects(subject).to eq(edge) }
    end

    describe 'non existing' do
      subject { Nebula::Edge.find(edge.id + 1) }
      it { expects(subject).to eq(nil) }
    end
  end

  describe '::count' do
    let!(:edges) do
      3.times.map do
        Nebula::Edge.create(label: :hello, from: from, to: to)
      end
    end

    it { expects(Nebula::Edge.count).to eq(3) }
  end

  describe '::destroy_all' do
    let!(:nodes) do
      3.times.map do
        Nebula::Edge.create(label: :hello, from: from, to: to)
      end
    end

    it { expects { Nebula::Edge.destroy_all }.to change(Nebula::Edge, :count) }
  end

  describe '::index_names' do
    subject { Nebula::Edge.index_names }
    it { expects(subject).to match_array(%w{ index_on_nebula_edges_label nebula_edges_pkey }) }
  end

  describe 'save' do
    describe 'with valid attribtes' do
      subject { Nebula::Edge.new(label: :hello, from: from, to: to) }

      it { expects { subject.save }.to change(Nebula::Edge, :count).by(1) }
      it { expects(subject.save.id).to be_kind_of(Integer) }
      it { expects(subject.save.label).to eq('hello') }
      it { expects(subject.save.from).to eq(from) }
      it { expects(subject.save.to).to eq(to) }
    end

    describe 'with invalid attributes' do
      subject { Nebula::Edge.new(from: from, to: to) }
      it { expects { subject.save }.to raise_error(PG::NotNullViolation) }
    end
  end
end
