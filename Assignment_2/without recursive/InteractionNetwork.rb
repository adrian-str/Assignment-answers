require 'rest-client'
require 'json'

class InteractionNetwork
  
  attr_accessor :network
  attr_accessor :members
  attr_accessor :kegg_path
  attr_accessor :go_terms
  @@all_interactions=[]
  
  def initialize(params={})
    @network = params.fetch(:network,0)
    @members = params.fetch(:members,'NA')
    @kegg_path = annotate_kegg(ids=@members)
    @go_terms = annotate_GO(ids=@members)
    @@all_interactions << self
  end
  
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})
    return response
    
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  # now we are returning 'False', and we will check that with an \"if\" statement in our main code
  end
   
  def self.get_agi(file)
    @@genes=[]
    File.open(file).each do |code|
      @@genes << code.strip.downcase
    end
    return @@genes
  end
  
  def self.get_interacting
    return @@interacting
  end
  
  def self.search_interactors
    @@counter=0
    @@interacting=Hash.new
      
    @@genes.each do |code|
      
      InteractionNetwork.get_interactors(code)
      
    end
    
  end
  
  def self.get_interactors(code,cutv=0.485)
      genes=@@genes
      res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{code}/?format=tab25")
      miscore=/i\w+-\w+:(0\.\d+)/
      if res
        intact=res.body.split("\n")
        intact.each do |int|
          
          next if int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)\(locus\sname\)/).nil?
             
            g1,g2=int.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)\(locus\sname\)/)
          next if g1.nil?||g2.nil?
            g1=g1[0]
            g2=g2[0]
            
          
          if g1.downcase==code.downcase and g2.downcase != code.downcase #get the interactor not the same gene
            
            g1=g2
            
          end
          
          score=int.match(miscore)[1].to_f
          
          next if score<cutv
          if genes.include?(g1.downcase)
             @@interacting[code]=g1
             
            
          else
            g0=g1
            res = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/interactor/#{g0}/?format=tab25")
            if res
              intact2=res.body.split("\n")
              intact2.each do |int2|
          
                next if int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/).nil?
               
                g1,g2=int2.scan(/(A[Tt]\d[Gg]\d\d\d\d\d)/)
                next if g1.nil?||g2.nil?
                g1=g1[0]
                g2=g2[0]
              
                
                if g1.downcase==g0.downcase #get the interactor not the same gene
              
                  g1=g2
              
                end
                next if g1.downcase==code.downcase
                score=int.match(miscore)[1].to_f
            
                next if score<cutv
                if genes.include?(g1.downcase)
                  if !@@interacting.keys.include?(code) # to avoid over-writing interactions
                      @@interacting[code]=[g0,g1]
                  end
                end
              end
            
            
            end
          end  
            
        end
      end
    
    
  end  

  def annotate_kegg(ids,db="genes",field="pathways")
    
    ids.each do |id|
    
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/ath:#{id}/#{field}.json")
      annotations=[]
      if resp
        res=JSON.parse(resp.body)[0]
        res.each do |term|
          kegg_id=term[0]
          kegg_p=term[1]
          annotation=[kegg_id,kegg_p]
          annotations << annotation
        end
      end
      return annotations 
    end    
      
  end    
  
  def annotate_GO(ids,db="uniprot",field="dr")
    
    ids.each do |id|
    
      resp = InteractionNetwork.fetch("http://togows.org/entry/#{db}/#{id}/#{field}.json")
      annotations=[]
      if resp
        res=JSON.parse(resp.body)[0]
        res["GO"].each do |term|
          if term[1]=~/P:/ #P=biological processes
            goid=term[0]
            goterm=term[1].match(/:(.+)/)[1]
            annotation=[goid,goterm]
            annotations << annotation
            
          end
        end
        return annotations.uniq # some GO terms are repeated in this database
      end
      
    end    
        
  end
  
  def self.load
    count=0
    ids=[]
    @@interacting.each do |key,value|
      count+=1
      if value.is_a?(Array)
        value.each do |v|
          ids << v  
        end
        ids << key
      elsif value.is_a?(String)
      ids=[key,value]
      end
      InteractionNetwork.new(:network => count, :members =>ids)
    end
  end
  
  def self.get_all
    return @@all_interactions
  end
end