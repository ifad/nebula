require 'spec_helper'

describe Nebula::Query do
  let!(:select) { "SELECT #{nodes}.* FROM #{nodes}" }
  let!(:nodes)  { Nebula::Node.table_name }
  let!(:edges)  { Nebula::Edge.table_name }

  describe '#to_sql' do
    context "empty" do
      let(:query) { Nebula::Query.new }
      it { expects(query.to_sql).to eq(select) }
    end

    context 'with label' do
      context 'string' do
        let(:query) { Nebula::Query.new(label: 'foo') }
        let(:where) { "(#{nodes}.label = 'foo')" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'non-string' do
        let(:query) { Nebula::Query.new(label: 5) }
        let(:where) { "(#{nodes}.label = '5')" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end
    end

    context 'with data component:' do
      context 'string key' do
        let(:query) { Nebula::Query.new(data: { 'foo' => 'bar' }) }
        let(:where) { "((#{nodes}.data->'foo')::text = '\"bar\"')" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'int key' do
        let(:query) { Nebula::Query.new(data: { 500 => 'bar' }) }
        let(:where) { "((#{nodes}.data->500)::text = '\"bar\"')" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'int value' do
        let(:query) { Nebula::Query.new(data: { 'foo' => 842 }) }
        let(:where) { "((#{nodes}.data->'foo')::text = '842')" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'array value' do
        let(:query) { Nebula::Query.new(data: { 'foo' => [ 'bar', 547 ] }) }
        let(:where) { "((#{nodes}.data->'foo')::text IN ('\"bar\"', '547'))" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'hash value' do
        let(:query) { Nebula::Query.new(data: { 'foo' => { 'bar' => [ 'baz', 807 ] } }) }
        let(:where) { "((#{nodes}.data#>'{foo,bar}')::text IN ('\"baz\"', '807'))" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'multiple keys' do
        let(:query) { Nebula::Query.new(data: { 'foo' => 'bar', 'baz' => { 'bot' => 5 } }) }
        let(:where) { "(((#{nodes}.data->'foo')::text = '\"bar\"') AND ((#{nodes}.data#>'{baz,bot}')::text = '5'))" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end

      context 'array' do
        let(:query) { Nebula::Query.new(data: [ { 'foo' => 'bar' }, { 'baz' => { 'bot' => 5 }, 'fuzz' => 'fort' } ]) }
        let(:where) { "(((#{nodes}.data->'foo')::text = '\"bar\"') OR (((#{nodes}.data#>'{baz,bot}')::text = '5') AND ((#{nodes}.data->'fuzz')::text = '\"fort\"')))" }
        it { expects(query.to_sql).to eq("#{select} WHERE #{where}") }
      end
    end

    context 'with edge component' do
      describe 'any in' do
        let(:query) { Nebula::Query.new(in: { }) }
        let(:sub)   { "SELECT #{edges}.to_node_id FROM #{edges}" }
        let(:where) { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'any out' do
        let(:query) { Nebula::Query.new(out: { }) }
        let(:sub)   { "SELECT #{edges}.from_node_id FROM #{edges}" }
        let(:where) { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'in with label' do
        let(:query)     { Nebula::Query.new(in: { label: 'foo' }) }
        let(:sub_where) { "#{edges}.label = 'foo'" }
        let(:sub)       { "SELECT #{edges}.to_node_id FROM #{edges} WHERE (#{sub_where})" }
        let(:where)     { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'in with from' do
        let(:query) { Nebula::Query.new(in: { label: 'foo', from: { data: { 'foo' => 'bar' } } }) }
        let(:sub_sub_where) { "(#{nodes}.data->'foo')::text = '\"bar\"'" }
        let(:sub_sub)       { "SELECT #{nodes}.id FROM #{nodes} WHERE (#{sub_sub_where})" }
        let(:sub_where)     { "(#{edges}.label = 'foo') AND (#{edges}.from_node_id IN (#{sub_sub}))" }
        let(:sub)           { "SELECT #{edges}.to_node_id FROM #{edges} WHERE #{sub_where}" }
        let(:where)         { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'in with to' do
        let(:query) { Nebula::Query.new(in: { label: 'foo', to: { data: { 'foo' => 'bar' } } }) }
        let(:sub_sub_where) { "(#{nodes}.data->'foo')::text = '\"bar\"'" }
        let(:sub_sub)       { "SELECT #{nodes}.id FROM #{nodes} WHERE (#{sub_sub_where})" }
        let(:sub_where)     { "(#{edges}.label = 'foo') AND (#{edges}.to_node_id IN (#{sub_sub}))" }
        let(:sub)           { "SELECT #{edges}.to_node_id FROM #{edges} WHERE #{sub_where}" }
        let(:where)         { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'out with label' do
        let(:query)     { Nebula::Query.new(out: { label: 'foo' }) }
        let(:sub_where) { "#{edges}.label = 'foo'" }
        let(:sub)       { "SELECT #{edges}.from_node_id FROM #{edges} WHERE (#{sub_where})" }
        let(:where)     { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'out with from' do
        let(:query) { Nebula::Query.new(out: { label: 'foo', from: { data: { 'foo' => 'bar' } } }) }
        let(:sub_sub_where) { "(#{nodes}.data->'foo')::text = '\"bar\"'" }
        let(:sub_sub)       { "SELECT #{nodes}.id FROM #{nodes} WHERE (#{sub_sub_where})" }
        let(:sub_where)     { "(#{edges}.label = 'foo') AND (#{edges}.from_node_id IN (#{sub_sub}))" }
        let(:sub)           { "SELECT #{edges}.from_node_id FROM #{edges} WHERE #{sub_where}" }
        let(:where)         { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end

      describe 'out with to' do
        let(:query) { Nebula::Query.new(out: { label: 'foo', to: { data: { 'foo' => 'bar' } } }) }
        let(:sub_sub_where) { "(#{nodes}.data->'foo')::text = '\"bar\"'" }
        let(:sub_sub)       { "SELECT #{nodes}.id FROM #{nodes} WHERE (#{sub_sub_where})" }
        let(:sub_where)     { "(#{edges}.label = 'foo') AND (#{edges}.to_node_id IN (#{sub_sub}))" }
        let(:sub)           { "SELECT #{edges}.from_node_id FROM #{edges} WHERE #{sub_where}" }
        let(:where)         { "#{nodes}.id IN (#{sub})" }
        it { expects(query.to_sql).to eq("#{select} WHERE (#{where})") }
      end
    end
  end
end
