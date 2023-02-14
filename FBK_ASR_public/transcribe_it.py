import sys, os, glob2
from transformers import pipeline
import librosa
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--wav_dir", type=str, required=True, help="wav" )
parser.add_argument("--output_dir", type=str, required=True, help="outdir" )
parser.add_argument("--device", type=int, default=0, required=False, help="The device to run the pipeline on.")
parser.add_argument("--model", type=str, default="./wavlm-large-it-cv10_tutto.3.256K.msb.p2", help="wav" )
parser.add_argument("--chunk_size", type=float, default=30, help="chunk size" )
args = parser.parse_args()

device=args.device
wav_dir=args.wav_dir
out_dir=args.output_dir
model=args.model
chunk_size=args.chunk_size

os.makedirs(out_dir, exist_ok=True)

p = pipeline("automatic-speech-recognition", model=model, feature_extractor=model, device=device)
wav_file_list = glob2.glob(f"{wav_dir}/**/*.wav")

print(f"Processing {len(wav_file_list)} wav files")
for wav_file in wav_file_list: 
 print(f"will decode {wav_file}")

# exit(1)
 
for wav_file in wav_file_list: 
 print(f"now decoding {wav_file}")
 audio, sr =librosa.load(wav_file,sr=16000)
 hyp=p(audio,chunk_length_s=chunk_size,stride_length_s=(3, 2), return_timestamps="word")
 # out_file=f"{out_dir}/{os.path.basename(wav_file).strip('.wav')}.txt"
 out_file=f"{out_dir}/{os.path.basename(wav_file).replace('.wav','.ts.txt')}"
 f = open(out_file, "w")
 print(f"writing {out_file}")
 text=""
 for w in hyp['chunks']:
  text = f"{text} {w['text']} {w['timestamp']}"
 f.write(text)
 f.close

    





