require 'spec_helper'

describe "Nebula Search" do

  # see spec/support/data.rb
  before { create_nebula }

  describe 'by query' do

    describe 'find by label' do
      subject { Nebula::Node.query(label: 'foo') }
      it { expects(subject.length).to eq(1) }
      it { expects(subject.first.data).to eq("verified" =>  true) }
    end

    describe 'find by data attribute' do
      context 'string value' do
        subject { Nebula::Node.query(data: { foo: 'bar' }) }
        it { expects(subject.length).to eq(2) }
        it { expects(subject.map { |node| node.data['bar'] }).to match_array(%w{ baz bot }) }
      end

      context 'integer value' do
        subject { Nebula::Node.query(data: { foo: 5 }) }
        it { expects(subject.length).to eq(1) }
        it { expects(subject.first.label).to eq('foo5') }
      end

      context 'float value' do
        subject { Nebula::Node.query(data: { foo: 5.2 }) }
        it { expects(subject.length).to eq(1) }
        it { expects(subject.first.label).to eq('foo5.2') }
      end

      context 'conjunctive attributes' do
        subject { Nebula::Node.query(data: { foo: 'bar', bar: 'baz' }) }
        it { expects(subject.length).to eq(1) }
        it { expects(subject.first.label).to eq('foobarbarbaz') }
      end

      context 'disjunctive attributes' do
        subject { Nebula::Node.query(data: [ { bar: 'baz' }, { bar: 'bot' } ]) }
        it { expects(subject.length).to eq(2) }
        it { expects(subject.map(&:label)).to match_array(%w{ foobarbarbaz foobarbarbot }) }
      end

      context 'deep attributes' do
        subject { Nebula::Node.query(data: { foo: { bar: 'baz' } }) }
        it { expects(subject.length).to eq(1) }
        it { expects(subject.first.label).to eq('deepfoobarbaz') }
      end
    end

    describe 'find by incoming edge label' do
      subject { Nebula::Node.query(in: { label: 'foo' }) }
      it { expects(subject.length).to eq(2) }
      it { expects(subject.map(&:label)).to match_array(%w{ in_one in_two }) }
    end

    describe 'find by incoming edge from node' do
      subject { Nebula::Node.query(in: { label: 'internal', from: { label: 'root_b' } }) }
      it { expects(subject.length).to eq(1) }
      it { expects(subject.first.label).to eq('internal_a') }
    end

    describe 'find by incoming edge through node' do
      subject { Nebula::Node.query(in: { label: 'leaf', from: { in: { label: 'internal', from: { label: 'root_b' } } } }) }
      it { expects(subject.length).to eq(2) }
      it { expects(subject.map(&:label)).to match_array(%w{ leaf_a leaf_b }) }
    end

    describe 'find by outgoing edge label' do
      subject { Nebula::Node.query(out: { label: 'bar' }) }
      it { expects(subject.length).to eq(1) }
      it { expects(subject.first.label).to eq('root') }
    end

    describe 'find by outgoing edge to node' do
      subject { Nebula::Node.query(out: { label: 'leaf', to: { label: 'leaf_c' } }) }
      it { expects(subject.length).to eq(1) }
      it { expects(subject.first.label).to eq('internal_b') }
    end

    describe 'find by outgoing edge through node' do
      subject { Nebula::Node.query(out: { label: 'internal', to: { out: { label: 'leaf', to: { label: 'leaf_a' } } } }) }
      it { expects(subject.length).to eq(2) }
      it { expects(subject.map(&:label)).to match_array(%w{ root_a root_b }) }
    end
  end
end
