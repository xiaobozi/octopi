require 'spec_helper'

describe Octopi::Gist do
  let(:gist) { Octopi::Gist.find(1115247) }

  context "unauthenticated" do
    it "can find all a user's gists" do
      gists = Octopi::Gist.for_user("fcoury")
      gists.count.should == 30
    end
    
    it "can create an anonymous gist" do
      gist = Octopi::Gist.create(:files => { "file.rb" => { :content => "puts 'hello world'" }})
      gist.owner.should be_nil
      # Check ensuring that public=true is sent through.
      WebMock.should have_requested(:post, base_url + "gists").with(:body => "files[file.rb][content]=puts%20'hello%20world'&public=true")
    end
    
    it "cannot retreive starred gists" do
      lambda { Octopi::Gist.starred }.should raise_error(Octopi::NotAuthenticated)
    end
    
    it "cannot star a gist" do
      lambda { gist.star! }.should raise_error(Octopi::NotAuthenticated)
    end
  end
  
  context "authenticated" do
    before do
      stub_successful_login!
      Octopi.authenticate! :username => "radar", :password => "password"
    end
    
    it "can create a public gist" do
      gist = Octopi::Gist.create(:files => { "file.rb" => { :content => "puts 'hello world'" }})
      # Check ensuring that public=true is sent through and request is authenticated
      # TODO: Why are these params reversed from the private example?
      WebMock.should have_requested(:post, authenticated_base_url + "gists").with(:body => "files[file.rb][content]=puts%20'hello%20world'&public=true")

      gist.owner.login.should == "radar"
    end
    
    it "can create a private gist" do
      gist = Octopi::Gist.create(:public => false, :files => { "file.rb" => { :content => "puts 'hello world'" }})
      # TODO: Why are these params reversed from the public example?
      WebMock.should have_requested(:post, authenticated_base_url + "gists").with(:body => "public=false&files[file.rb][content]=puts%20'hello%20world'")
      
      gist.owner.login.should == "radar"
    end
    
    context "as rails3book" do
      let(:gists_url) { authenticated_base_url("rails3book") + "gists" }
      before do
        # For hopefully obvious reasons...
        # I don't want to show you my private gists.
        # BECAUSE THEY ARE PRIVATE.
        # Geez.
        stub_successful_login!("rails3book")
        Octopi.authenticate! :username => "rails3book", :password => "password"
      end

      it "can retreive own gists" do
        stub_request(:get, gists_url).to_return(fake("gists"))
        
        gists = Octopi::Gist.mine
        # There should be at least one private gist
        gists.any? { |gist| gist.public == false }.should be_true
        WebMock.should have_requested(:get, gists_url)
      end
      
      it "can retreive own starred gists" do
        stub_request(:get, gists_url + "/starred").to_return(fake("gists/starred"))
        Octopi::Gist.starred
        WebMock.should have_requested(:get, gists_url + "/starred")
      end
      
      context "starring" do
        let(:url) { "https://rails3book:password@api.github.com/gists/1115247/star" }
        before do
          authenticated_api_stub("gists/1115247", "rails3book")
          authenticated_api_stub("gists/1115247/comments", "rails3book")
          authenticated_api_stub("gists/1115247/star", "rails3book")
        end

        it "setting starred status for a gist" do
          stub_request(:put, url).to_return(:status => 204)
          gist.star!
          WebMock.should have_requested(:put, url)
        end

        it "gist is starred" do
          stub_request(:get, url).to_return(:status => 204)
          gist.should be_starred
        end

        it "gist is not starred" do
          stub_request(:get, url).to_return(:status => 404)
        end
      end
    end
  end
  
  context "for a gist" do

    it "retreiving user" do
      gist.user.is_a?(Octopi::User).should be_true
    end

    it "retreiving files" do
      gist.files.first.is_a?(Octopi::Gist::GistFile).should be_true
    end

    it "retreiving history" do
      gist.history.first.is_a?(Octopi::Gist::History).should be_true
    end
    
    it "retreiving comments" do
      gist.comments.first.is_a?(Octopi::Gist::Comment).should be_true
    end
    
    it "has attributes" do
      gist.updated_at.should == "2011-07-30T05:53:43Z"
      gist.git_pull_url.should == "git://gist.github.com/1115247.git"
      gist.forks.should == []
      gist.public.should be_true
      gist.description.should == ""
      gist.created_at.should == "2011-07-30T05:53:43Z"
      gist.html_url.should == "https://gist.github.com/1115247"
      gist.id.should == "1115247"
    end

    it "links files to gist" do
      gist.files.first.gist.should == gist
    end

    it "links histories to gist" do
      gist.history.first.gist.should == gist
    end

    it "links comments to gist" do
      gist.comments.first.gist.should == gist
    end

    it "updates description" do
      gist = Octopi::Gist.find(1236602)
      url = "https://api.github.com/gists/1236602"
      attributes = { :description => "New Description" }
      stub_request(:post, url).
         with(:body => attributes.to_json).to_return(fake("gists/update"))

      gist = gist.update_attributes(attributes)
      gist.description.should == "New Description"

      WebMock.should have_requested(:post, url)
    end

    it "unstars a gist"
    it "forks a gist"
    it "deletes a gist"
  end
end
