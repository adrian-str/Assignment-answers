class Gene
# The gene_information file has 3 columns:
  attr_accessor :gene_ID
  attr_accessor :gene_name
  attr_accessor :mut_phenotype
  
  def initialize(params = {}) 
    @gene_ID = params.fetch(:gene_ID, "AT0G0000")
    @gene_name = params.fetch(:gene_name, "abc")
    @mut_phenotype = params.fetch(:mut_phenotype, "weirdo")
  end
# To create the objects for this class (and the others) I use a class method:
  def Gene.get_genes(file_path)
    IO.foreach("file_path", $/){ |record|
      if __LINE__==1 #skip the header
          next
      end
      record.split("\t") = id, name, phenotype
      if id.match(/A[Tt]\d[Gg]\d\d\d\d\d/)
        Gene.new(gene_ID: id, gene_name: name, mut_phenotype: phenotype)
      else
        puts ("Gene ID: #{id} incorrect")
      end}
    
  end
  
  
end