require 'spec_helper'

describe ActiveFedora::RelsInt do
  before :all do
    class Foo < ActiveFedora::Base
      include ActiveFedora::RelsInt
    end
  end
  
  after :all do
    Object.send(:remove_const, :Foo) # cleanup
  end
  
  describe "modules" do
    it "should exist" do
      (defined? ActiveFedora::RelsInt).should be_true
      (defined? ActiveFedora::RelsInt::Datastream).should be_true
    end
  end

  it "should add the appropriate ds_spec and accessor methods when mixed in" do
    Foo.ds_specs.keys.should include 'RELS-INT'
    Foo.ds_specs['RELS-INT'][:type].should == ActiveFedora::RelsInt::Datastream
  end

  it "should serialize to appropriate RDF-XML" do
    blank_relsint = fixture('rels_int_blank.xml').read
    inner = mock("DigitalObject")
    inner.stubs(:pid).returns("test:relsint")
    repo = mock("Repository")
    #repo.expects(:datastream_dissemination).with(:dsid=>"RELS-INT", :pid=>"test:relsint").returns("")
    #inner.stubs(:repository).returns(repo)
    test_obj = ActiveFedora::RelsInt::Datastream.new(inner,"RELS-INT")
    Nokogiri::XML.parse(test_obj.content).should be_equivalent_to Nokogiri::XML.parse(blank_relsint)
  end
  
  describe ActiveFedora::RelsInt::Datastream do
    it "should load relationships from foxml into the appropriate graphs" do
      pending "mocking the fcrepo responses"
    end
    it "should load relationships into appropriate graphs when assigned content" do
      test_relsint = fixture('rels_int_test.xml').read
      inner = mock("DigitalObject")
      inner.stubs(:pid).returns("test:relsint")
      inner.stubs(:internal_uri).returns("info:fedora/test:relsint")
      test_obj = ActiveFedora::RelsInt::Datastream.new(inner,"RELS-INT")
      test_obj.content=test_relsint
      dc = ActiveFedora::Datastream.new(inner,"DC")
      triples = test_obj.relationships(dc,:is_metadata_for)
      e = ['info:fedora/test:relsint/DC','info:fedora/fedora-system:def/relations-external#isMetadataFor','info:fedora/test:relsint/RELS-INT'].
        map {|x| RDF::URI.new(x)}
      triples.should == [RDF::Statement.new(*e)]
    end    
    it "should propagate relationship changes to the appropriate graph in RELS-INT" do
      test_relsint = fixture('rels_int_test.xml').read
      inner = mock("DigitalObject")
      inner.stubs(:pid).returns("test:relsint")
      inner.stubs(:internal_uri).returns("info:fedora/test:relsint")
      test_obj = ActiveFedora::RelsInt::Datastream.new(inner,"RELS-INT")
      dc = ActiveFedora::Datastream.new(inner,"DC")
      rels_ext = ActiveFedora::Datastream.new(inner,"RELS-EXT")
      test_obj.add_relationship(dc,:is_metadata_for, test_obj)
      test_obj.add_relationship(rels_ext,:asserts, "FOO", true)
      test_obj.add_relationship(test_obj,:asserts, "BAR", true)
      test_obj.serialize!
      puts test_obj.content
      Nokogiri::XML.parse(test_obj.content).should be_equivalent_to Nokogiri::XML.parse(test_relsint)
    end
  end
end