import tensorflow as tf
import opennmt as onmt


#
# defines the [model] type to train, called in the [train-*.sh] script
# tip on overfitting: for single-pair/smaller models dropout=0.3, while for multilingual dropout=0.1 shows best result
#

class TransformerSA(onmt.models.Transformer):
  """Defines a Transforme:wqr model as decribed in https://arxiv.org/abs/1706.03762."""
  def __init__(self, dtype=tf.float32, share_embeddings=onmt.models.EmbeddingsSharingLevel.NONE, dropout=0.1):
     super(TransformerSA, self).__init__(
        source_inputter=onmt.inputters.WordEmbedder(embedding_size=512),
        target_inputter=onmt.inputters.WordEmbedder(embedding_size=512),
        num_layers=6,
        num_units=512,
        num_heads=8,
        ffn_inner_dim=2048,
        dropout=0.1,
        attention_dropout=0.1,
        ffn_dropout=0.1,
        share_embeddings=share_embeddings)


#class TransformerShareEmbs(TransformerSA):
#    """Defines a Transformer model that uses shared encoder-decoder embeddings."""
#    def __init__(self):
#        super(TransformerShareEmbdAll, self).__init__(
#            share_embeddings=onmt.models.EmbeddingsSharingLevel.ALL
#        )


class TransformerShareEmbsDropout(TransformerSA):
  """Defines a Transformer model that uses shared encoder-decoder embeddings."""
  def __init__(self):
    super(TransformerShareEmbsDropout, self).__init__(
            dropout=0.3,
            share_embeddings=onmt.models.EmbeddingsSharingLevel.ALL)


# update accordingly 
model = TransformerShareEmbsDropout
#model = TransformerSA
