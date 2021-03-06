This subcommand outputs the classifications made by pplacer in a database or in a tabular format appropriate for use with R.

*The classifications made by the current implementation of pplacer are done with a simple, root-dependent algorithm.
We are currently working on improved algorithms.*
For best results, first taxonomically root the tree in your reference package (so that the root of the tree corresponds to the "deepest" evolutionary event according to the taxonomy).
This can be done automatically the `taxit reroot` command in taxtastic.
(Note that as of 27 May 2011, this requires the dev version of biopython available on github.)

The classifications are simply done by containment.
Say clade *A* of the reference tree is the smallest such that contains a given placement.
The most specific classification for that read will be the lowest common ancestor of the taxonomic classifications for the leaves of *A*.
If the desired classification is more specific than that, then we get a disconnect between the desired and the actual classification.
For example, if we try to classify at the species level and the clade LCA is a genus, then we will get a genus name.
If there is uncertainty in read placement, then there is uncertainty in classification.

For example, here is a classification list made for one read using the tabular output.
The columns are as follows: read name, attempted rank for classification, actual rank for classification, taxonomic identifier, and confidence.
You can see that in this example, there is some uncertainty at and below species, but only one classification at the genus level.

::

  GLKT0ZE01CQ2BU                      root          root       1          1
  GLKT0ZE01CQ2BU                below_root    below_root  131567          1
  GLKT0ZE01CQ2BU              superkingdom  superkingdom       2          1
  GLKT0ZE01CQ2BU        below_superkingdom  superkingdom       2          1
  GLKT0ZE01CQ2BU  below_below_superkingdom  superkingdom       2          1
  GLKT0ZE01CQ2BU               superphylum  superkingdom       2          1
  GLKT0ZE01CQ2BU                    phylum        phylum    1239          1
  GLKT0ZE01CQ2BU                 subphylum        phylum    1239          1
  GLKT0ZE01CQ2BU                     class         class  186801          1
  GLKT0ZE01CQ2BU                  subclass         class  186801          1
  GLKT0ZE01CQ2BU                     order         order  186802          1
  GLKT0ZE01CQ2BU               below_order         order  186802          1
  GLKT0ZE01CQ2BU         below_below_order         order  186802          1
  GLKT0ZE01CQ2BU                  suborder         order  186802          1
  GLKT0ZE01CQ2BU                    family        family  186804          1
  GLKT0ZE01CQ2BU              below_family        family  186804          1
  GLKT0ZE01CQ2BU                     genus         genus    1257          1
  GLKT0ZE01CQ2BU             species_group         genus    1257          1
  GLKT0ZE01CQ2BU          species_subgroup         genus    1257          1
  GLKT0ZE01CQ2BU                   species         genus    1257  0.0732247
  GLKT0ZE01CQ2BU                   species       species    1261   0.853561
  GLKT0ZE01CQ2BU                   species       species  341694   0.073214
  GLKT0ZE01CQ2BU             below_species         genus    1257  0.0732247
  GLKT0ZE01CQ2BU             below_species       species    1261   0.853561
  GLKT0ZE01CQ2BU             below_species       species  341694   0.073214


Classifiers
===========

``guppy classify`` has a variety of classifiers.

.. glossary::

    pplacer
      Takes placefiles as input and classifies using the method described
      above.

      When refining classifications for the ``multiclass`` table, first, all of
      the classifications with a likelihood of less than the value of
      ``--multiclass-cutoff`` are discarded. Next, if the value for
      ``--bayes-cutoff`` is nonzero, ranks below the most specific rank with
      bayes factor evidence greater than or equal to that cutoff are discarded.
      Otherwise, the likelihoods of remaining classifications are summed
      per-rank, and ranks with a likelihood sum of less than ``--cutoff`` are
      discarded.

    nbc
      Takes sequences via the ``--nbc-sequences`` flag and classifies them with
      a naive bayes classifier.

      The input sequences must be an alignment by default, either aligned to
      the reference sequences or include an alignment of the reference
      sequences (in the same manner pplacer does). If the ``--no-pre-mask``
      flag is specified, the input sequences may be unaligned, and must not
      also contain reference sequences.

      When refining classifications for the ``multiclass`` table, for each
      rank, the best classification with a bootstrap above the value of
      ``--bootstrap-cutoff`` is selected. Ranks with no such classifications
      are discarded.

    rdp
      Takes the output of Mothur's `classify.seqs`_ via the ``--rdp-results``
      flag and inserts the classifications into the database. This should be
      the ``.taxonomy`` file.

      Refinement for ``multiclass`` is done the same as for :term:`nbc`.

    blast
      Takes the output of BLAST_ via the ``--blast-results`` flag and inserts
      the classifications into the database. The output must be in outfmt 6.

      Refinement for ``multiclass`` is done the same as for :term:`nbc`.

    hybrid
      Still in flux.


Sqlite
======

``guppy classify`` writes its output into a sqlite3 database. The argument to
the ``--sqlite`` flag is the sqlite3 database into which the results should be
put. This database must have first been intialized using :ref:`rppr prep_db
<rppr_prep_db>`.

The following tables are populated by ``guppy classify``:

* ``runs`` -- describes each separate invocation of ``guppy classify``; exactly
  one row will be added for each invocation.
* ``placements`` -- describes groups of sequences. Each row will represent one
  or more sequences and indicate which classifier was used.
* ``placement_names`` -- indicates which sequences are in this group of
  sequences and where each sequence came from.
* ``placement_classifications`` -- indicates tax_id and likelihood for the
  :term:`pplacer` and :term:`hybrid` classifiers.
* ``placement_evidence`` -- indicates bayes factor evidence for the
  :term:`pplacer` and :term:`hybrid` classifiers.
* ``placement_position`` -- indicates placement position for the
  :term:`pplacer` and :term:`hybrid` classifiers.
* ``placement_median_identities`` -- indicates sequence median percent identity
  for the :term:`pplacer` and :term:`hybrid` classifiers when run with the
  ``--tax-median-identity-from`` flag.
* ``placement_nbc`` -- indicates tax_id and bootstrap value for the
  :term:`nbc`, :term:`rdp`, :term:`blast`, and :term:`hybrid` classifiers.
* ``multiclass`` -- indicates the best classification and rank of
  classification from any classifier for a given sequence name and desired rank
  of classification. There might be multiple classifications for a particular
  sequence and desired rank, but only when using the :term:`pplacer` or
  :term:`hybrid` classifiers.


.. _classify.seqs: http://www.mothur.org/wiki/Classify.seqs
.. _BLAST: http://www.ncbi.nlm.nih.gov/books/NBK1763/
