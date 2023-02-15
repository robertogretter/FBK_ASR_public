# FBK_ASR_public
Scripts to perform Italian ASR using a WavLM E2E system; LM adaptation is also provided. 

##### FBK - SpeechTek, February 2023
##### Marco Matassoni, Roberto Gretter
##### matasso@fbk.eu, gretter@fbk.eu

In this repository we put some script and data to perform Language Model (LM) adaptation and automatic Speech Recognition (ASR) on Italian, using WavLM (https://huggingface.co/docs/transformers/model_doc/wavlm), fine-tuned on some hundreds of Italian audio data.

There are some huge files (.zip) to download from Google Drive folder FBK_ASR_public_data (link: https://drive.google.com/drive/folders/10kL8G-SU5meqXw0H3b0OLEOVhSvIyk5q ) and upload into FBK_ASR_public/:

```
    download from:  FBK_ASR_public_data / **italian.zip**
    extract:        unzip ~/Downloads/italian.zip
    move:           mv italian corpora/
    you should get: FBK_ASR_public/corpora/italian/
```
```
    download from:  FBK_ASR_public_data / **wavlm-large-it-cv10.zip**
    extract:        unzip ~/Downloads/wavlm-large-it-cv10.zip
    you should get: FBK_ASR_public/wavlm-large-it-cv10/
    you should get: FBK_ASR_public/wavlm-large-it-cv10_tutto.3.256K.msb.p2/
```
```
    download from:  FBK_ASR_public_data / NorTex.zip
    extract:        unzip ~/Downloads/NorTex.zip
    you should get: FBK_ASR_public/NorTex/
```
```
    download from:  FBK_ASR_public_data / audio_samples.zip
    extract:        unzip ~/Downloads/audio_samples.zip
    you should get: FBK_ASR_public/audio_samples/
```
```
    download from:  http://vectors.nlpl.eu/repository/20/52.zip
    extract:        unzip ~/Downloads/52.zip model.bin
    move:           mv model.bin corpora/italian/w2v_52_model.bin
    you should get: FBK_ASR_public/corpora/italian/w2v_52_model.bin
```

#### You should have python installed, together with all is needed, check here:
```
    https://huggingface.co/docs/transformers/model_doc/wavlm
    (make sure that your python is at least version 3.8.11)
    ./python --version         -->   Python 3.8.11
```

In particular there are:
```
    ReadMeFBK_ASR.txt             # documentation, this file
    mtsummit2021-seeds-GMF.pdf    # documentation, paper describing the adaptation method for LM, using a few data.

./audio_samples/
    # folder containing a couple of audio files in dentistry domain (.wav) with the corresponding manual transcription (.txt)
    # plus some text to perform LM adaptation in dentistry domain (GlOd.txt)
    # and ASR output folders (output_*)
    # please use filenames without strange characters (for instance àèéìòù, blanks, parenthesis, '`", etc.)


./wavlm-large-it-cv10/                          (no LM)
./wavlm-large-it-cv10_tutto.3.256K.msb.p1/      (big LM)
./wavlm-large-it-cv10_tutto.3.256K.msb.p2/      (small LM)
    # folders containing WavLM models with/without ready-to-use generic Italian LMs
./wavlm-large-it-cv10_Template/
    # template to build other WavLM models with an adapted LM


./corpora/italian/
    # folder containing several data useful to build new adapted LM:
    # *.nopunct.gz        normalized text data (EN20* : news of the last years; itwiki* : 2018 wikipedia dump)
    # all.3ngt            3grams computed on data which include all *.nopunct.gz - also some dictionary is present - used as a generic Italian LM
    # small.3ngt          3grams computed on a few data, to test if scripts work
    # italian.stm         file in the medical domain to check OOV and perplexity of LMs
    # w2v_52_model.bin    public word2vec model used to expand data for LM adaptation


Some scripts (shell, python, perl) to adapt a generic LM using some texts in a given domain, to run an ASR using an E2E system and possibly a LM, to evaluate the performance in case reference is available, etc. Usage details for some of them are below.
  ./transcribe_it.py     # performs ASR on all .wav files in a folder
  ./AdaptLM.sh           # builds an adapted LM using some seed data, described in mtsummit2021-seeds-GMF.pdf
  ./ngr2arpa.sh          # builds a LM without adaptation
  ./Eval.sh              # convert the ASR output and perform evaluation, if reference is available
  ./TLT2021EvalScript.pl # used by Eval.sh to perform WER computation
  ./Nortex/              # lots of text processing, included phonetic transcriptions, numbers, etc. - not documented, partly used by the main scripts
  ./bin/                 # several executables used by the main scripts
  ./here.sh              # definitions, included by several scripts - do not touch it

./transcribe_it.py
     # performs ASR on all .wav files in a folder; returns recognized words with time stamps (.ts.txt) in the output folder specified
   ./python ./transcribe_it.py --wav_dir ./audio_samples --output_dir ./audio_samples/output_p0 --model ./wavlm-large-it-cv10 --device -1
   ./python ./transcribe_it.py --wav_dir ./audio_samples --output_dir ./audio_samples/output_p1 --model ./wavlm-large-it-cv10_tutto.3.256K.msb.p1 --device -1
   ./python ./transcribe_it.py --wav_dir ./audio_samples --output_dir ./audio_samples/output_p2 --model ./wavlm-large-it-cv10_tutto.3.256K.msb.p2 --device -1
     # device -1 --> no GPU

./AdaptLM.sh
     # builds an adapted LM using some seed data, described in mtsummit2021-seeds-GMF.pdf
     # to check quickly if everything in the LM adaptation is working, using only a few data:
   sh ./AdaptLM.sh italian audio_samples/GlOd.txt AdaFolderTest test
     # to produce an adapted LM in dentistry domain:
   sh ./AdaptLM.sh italian audio_samples_glod/GlOd.txt AdaGlod 

./Eval.sh
     # processes the ASR output (file.ts.txt) and in case there is reference, performs evaluation.
   sh ./Eval.sh audio_samples audio_samples/output_p0


The sequence of commands below should:
    # build an adapted LM in dentistry domain:
 sh ./AdaptLM.sh italian audio_samples/GlOd.txt AdaGlod
    # this process will build in a few hours the following folders:
    # (2.7GB) AdaGlod/  # folder containing intermediate files and *arpa.gz LMs (complete and pruned)
                        # check AdaGlod/*report* for details - not needed for ASR, at the end it can be removed
    # (5.3GB) wavlm-large-it-cv10_AdaGlod.w2v_ctw60_mS40.all2/    # WavLM recognizer with complete adapted LM
    # (303MB) wavlm-large-it-cv10_AdaGlod.w2v_ctw60_mS40.all.p2/  # WavLM recognizer with pruned adapted LM

    # perform ASR using the adapted LM:
 ./python ./transcribe_it.py --wav_dir ./audio_samples --output_dir ./audio_samples/output_adap2  --model ./wavlm-large-it-cv10_AdaGlod.w2v_ctw60_mS40.all.p2 --device -1
 ./python ./transcribe_it.py --wav_dir ./audio_samples --output_dir ./audio_samples/output_adaall --model ./wavlm-large-it-cv10_AdaGlod.w2v_ctw60_mS40.all --device -1
    # audio_samples/output_ada* : for each audio file .wav in ./audio_samples, a .ts.txt file containing recognized words with time markers is produced

    # process and evaluate ASR output:
 sh ./Eval.sh audio_samples audio_samples/output_adap2
 sh ./Eval.sh audio_samples audio_samples/output_adaall
    # processes the ASR output (file.ts.txt) and in case there is reference, performs evaluation. Foreach audio file it builds:
    # file.txt                    # just ASR text, as it is
    # file.ctm, file.pctm         # one word (phrase - identified by silences - in .pctm) per line with time markers
    # file.trs                    # transcriber file, suitable to visualize/listen/modify the ASR output against the audio (http://trans.sourceforge.net/en/presentation.php)
    # file.norm.asr file norm.ref # normalized ASR and reference
    # file.wer                    # alignment of ASR versus reference, highligting errors. Last line contains the WER.
    # file.errors.stat.txt        # statistics over the errors
    # in addition, two files collect the statistics for all the audio files in the folder:
    # all.errors.stat.txt         # global error statistics
    # all.wer                     # individual + global WER


cat audio_samples/output_*/all.wer | grep " all " | sort -k2nr
WER=  13.36% (S=   63 I=    6 D=   18) / REFERENCE_WORDS=  651 - UTTERANCES=    2 - all audio_samples/output_p0
WER=  10.45% (S=   52 I=    6 D=   10) / REFERENCE_WORDS=  651 - UTTERANCES=    2 - all audio_samples/output_p1
WER=   9.98% (S=   50 I=    5 D=   10) / REFERENCE_WORDS=  651 - UTTERANCES=    2 - all audio_samples/output_p2
WER=   9.22% (S=   44 I=    5 D=   11) / REFERENCE_WORDS=  651 - UTTERANCES=    2 - all audio_samples/output_adaall
WER=   9.06% (S=   44 I=    4 D=   11) / REFERENCE_WORDS=  651 - UTTERANCES=    2 - all audio_samples/output_adap2

Results highligh that, on this small and not statistically relevant sample:
- even without LM (output_p0) the ASR is reasonable (~13% WER);
- using a generic LM improves (~10% WER); the pruned model is much smaller (470MB vs 2.3GB) than the complete but they have similar performance;
- using an adapted LM improves a little over a generic one (~9% WER); again the pruned model is much smaller (300MB vs 5.3GB) than the complete but they have similar performance.
```

