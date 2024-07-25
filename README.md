#  Yugo-LLaVA


______________

![image](/images/yugo-llava.webp)


Checkout the original LLaVA code, demo and paper here: https://github.com/haotian-liu/LLaVA

ORIGINAL LLaVA PAPER and LINKS:
*Visual instruction tuning towards large language and vision models with GPT-4 level capabilities.*

[[Project Page](https://llava-vl.github.io/)] [[Demo](https://llava.hliu.cc/)]  [[Data](https://github.com/haotian-liu/LLaVA/blob/main/docs/Data.md)] [[Model Zoo](https://github.com/haotian-liu/LLaVA/blob/main/docs/MODEL_ZOO.md)]

**Improved Baselines with Visual Instruction Tuning** [[Paper](https://arxiv.org/abs/2310.03744)] <br>
[Haotian Liu](https://hliu.cc), [Chunyuan Li](https://chunyuan.li/), [Yuheng Li](https://yuheng-li.github.io/), [Yong Jae Lee](https://pages.cs.wisc.edu/~yongjaelee/)

**Visual Instruction Tuning** (NeurIPS 2023, **Oral**) [[Paper](https://arxiv.org/abs/2304.08485)]<br>
[Haotian Liu*](https://hliu.cc), [Chunyuan Li*](https://chunyuan.li/), [Qingyang Wu](https://scholar.google.ca/citations?user=HDiw-TsAAAAJ&hl=en/), [Yong Jae Lee](https://pages.cs.wisc.edu/~yongjaelee/) (*Equal Contribution)



[![Code License](https://img.shields.io/badge/Code%20License-Apache_2.0-green.svg)](https://github.com/tatsu-lab/stanford_alpaca/blob/main/LICENSE)
[![Data License](https://img.shields.io/badge/Data%20License-CC%20By%20NC%204.0-red.svg)](https://github.com/tatsu-lab/stanford_alpaca/blob/main/DATA_LICENSE)
**Usage and License Notices**: The data and checkpoint is intended and licensed for research use only. They are also restricted to uses that follow the license agreement of LLaMA, Vicuna and GPT-4. The dataset is CC BY NC 4.0 (allowing only non-commercial use) and models trained using the dataset should not be used outside of research purposes.


## Contents
- [Install](#install)
- [LLaVA Weights](#llava-weights)
- [Demo](#Demo)
- [Model Zoo](https://github.com/haotian-liu/LLaVA/blob/main/docs/MODEL_ZOO.md)
- [Dataset](https://github.com/haotian-liu/LLaVA/blob/main/docs/Data.md)
- [Train](#train)
- [Evaluation](#evaluation)

## Install

1. Clone this repository and navigate to LLaVA folder
```bash
git clone https://github.com/SkunkworksAI/BakLLaVA.git
cd BakLLaVA
```

2. Install Package
```Shell
conda create -n llava python=3.10 -y
conda activate llava
pip install --upgrade pip  # enable PEP 660 support
pip install -e .
```

3. Install additional packages for training cases
```
pip install ninja
pip install flash-attn --no-build-isolation
```

### Upgrade to latest code base

```Shell
git pull
pip uninstall transformers
pip install -e .
```

## LLaVA Weights
Please check out our [Model Zoo](https://github.com/haotian-liu/LLaVA/blob/main/docs/MODEL_ZOO.md) for all public LLaVA checkpoints, and the instructions of how to use the weights.

## Demo

To run our demo, you need to prepare LLaVA checkpoints locally.  Please follow the instructions [here](#llava-weights) to download the checkpoints.

### Gradio Web UI

To launch a Gradio demo locally, please run the following commands one by one. If you plan to launch multiple model workers to compare between different checkpoints, you only need to launch the controller and the web server *ONCE*.

#### Launch a controller
```Shell
python -m llava.serve.controller --host 0.0.0.0 --port 10000
```

#### Launch a gradio web server.
```Shell
python -m llava.serve.gradio_web_server --controller http://localhost:10000 --model-list-mode reload
```
You just launched the Gradio web interface. Now, you can open the web interface with the URL printed on the screen. You may notice that there is no model in the model list. Do not worry, as we have not launched any model worker yet. It will be automatically updated when you launch a model worker.

#### Launch a model worker

This is the actual *worker* that performs the inference on the GPU.  Each worker is responsible for a single model specified in `--model-path`.

```Shell
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path liuhaotian/llava-v1.5-13b
```
Wait until the process finishes loading the model and you see "Uvicorn running on ...".  Now, refresh your Gradio web UI, and you will see the model you just launched in the model list.

You can launch as many workers as you want, and compare between different model checkpoints in the same Gradio interface. Please keep the `--controller` the same, and modify the `--port` and `--worker` to a different port number for each worker.
```Shell
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port <different from 40000, say 40001> --worker http://localhost:<change accordingly, i.e. 40001> --model-path <ckpt2>
```

#### Launch a model worker (Multiple GPUs, when GPU VRAM <= 24GB)

If the VRAM of your GPU is less than 24GB (e.g., RTX 3090, RTX 4090, etc.), you may try running it with multiple GPUs. Our latest code base will automatically try to use multiple GPUs if you have more than one GPU. You can specify which GPUs to use with `CUDA_VISIBLE_DEVICES`. Below is an example of running with the first two GPUs.

```Shell
CUDA_VISIBLE_DEVICES=0,1 python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path liuhaotian/llava-v1.5-13b
```

#### Launch a model worker (4-bit, 8-bit inference, quantized)

You can launch the model worker with quantized bits (4-bit, 8-bit), which allows you to run the inference with reduced GPU memory footprint, potentially allowing you to run on a GPU with as few as 12GB VRAM. Note that inference with quantized bits may not be as accurate as the full-precision model. Simply append `--load-4bit` or `--load-8bit` to the **model worker** command that you are executing. Below is an example of running with 4-bit quantization.

```Shell
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path liuhaotian/llava-v1.5-13b --load-4bit
```

#### Launch a model worker (LoRA weights, unmerged)

You can launch the model worker with LoRA weights, without merging them with the base checkpoint, to save disk space. There will be additional loading time, while the inference speed is the same as the merged checkpoints. Unmerged LoRA checkpoints do not have `lora-merge` in the model name, and are usually much smaller (less than 1GB) than the merged checkpoints (13G for 7B, and 25G for 13B).

To load unmerged LoRA weights, you simply need to pass an additional argument `--model-base`, which is the base LLM that is used to train the LoRA weights. You can check the base LLM of each LoRA weights in the [model zoo](https://github.com/haotian-liu/LLaVA/blob/main/docs/MODEL_ZOO.md).

```Shell
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path liuhaotian/llava-v1-0719-336px-lora-vicuna-13b-v1.3 --model-base lmsys/vicuna-13b-v1.3
```

### CLI Inference

Chat about images using LLaVA without the need of Gradio interface. It also supports multiple GPUs, 4-bit and 8-bit quantized inference. With 4-bit quantization, for our LLaVA-1.5-7B, it uses less than 8GB VRAM on a single GPU.

```Shell
python -m llava.serve.cli \
    --model-path liuhaotian/llava-v1.5-7b \
    --image-file "https://llava-vl.github.io/static/images/view.jpg" \
    --load-4bit
```

<img src="images/demo_cli.gif" width="70%">

## Train

LLaVA training consists of two stages: (1) feature alignment stage: use approximately 600K filtered CC3M to connect a *frozen pretrained* vision encoder to a *frozen LLM*; (2) visual instruction tuning stage: use 150K GPT-generated multimodal instruction-following to teach the model to follow multimodal instructions.

LLaVA is trained on 8 A100 GPUs with 80GB memory. To train on fewer GPUs, you can reduce the `per_device_train_batch_size` and increase the `gradient_accumulation_steps` accordingly. Always keep the global batch size the same: `per_device_train_batch_size` x `gradient_accumulation_steps` x `num_gpus`.

### Hyperparameters
We use a similar set of hyperparameters as Vicuna in finetuning.  Both hyperparameters used in pretraining and finetuning are provided below.

1. Pretraining

| Hyperparameter | Global Batch Size | Learning rate | Epochs | Max length | Weight decay |
| --- | ---: | ---: | ---: | ---: | ---: |
| LLaVA-13B | 256 | 1e-3 | 1 | 2048 | 0 |

2. Finetuning

| Hyperparameter | Global Batch Size | Learning rate | Epochs | Max length | Weight decay |
| --- | ---: | ---: | ---: | ---: | ---: |
| LLaVA-13B | 128 | 2e-5 | 1 | 2048 | 0 |

### Prepare Vicuna checkpoints

Before you start, prepare our base model Vicuna, which is an instruction-tuned chatbot. Please download its weights [here](https://github.com/lm-sys/FastChat#model-weights).

Vicuna has two versions: v0 and v1, the main difference between them is the prompt of format. We support both. To ensure the best performance, you need to specify the correct prompt version corresponding to the weights you download: `v0` for `v0` weights, and `v1` for all Vicuna `v1.x` models.

### Pretrain (feature alignment)

Please download the subset of the CC3M dataset we use in the paper [here](https://huggingface.co/datasets/liuhaotian/LLaVA-CC3M-Pretrain-595K).

Pretrain takes around 4 hours for LLaVA-13B on 8x A100 (80G). It takes around 2 hours for 7B checkpoints.

We recommend training with DeepSpeed as it can save a lot of GPU RAM. We provide training script with DeepSpeed [here](https://github.com/haotian-liu/LLaVA/blob/main/scripts/pretrain.sh).

You may run this with a single A100 GPU with the following code.  Please note that the `per_device_train_batch_size` * `gradient_accumulation_steps` should be equal to 128 to keep the global batch size the same.

<details>
<summary>Pretrain: LLaVA-13B, 1x A100 (80G).  Time: ~33 hours.</summary>

```Shell
python llava/train/train_mem.py \
    --model_name_or_path ./checkpoints/vicuna-13b \
    --version [v0 or v1] \
    --data_path /path/to/cc3m_595k.json \
    --image_folder /path/to/cc3m_595k_images \
    --vision_tower openai/clip-vit-large-patch14 \
    --tune_mm_mlp_adapter True \
    --mm_vision_select_layer -2 \
    --mm_use_im_start_end False \
    --mm_use_im_patch_token False \
    --bf16 True \
    --output_dir ./checkpoints/llava-13b-pretrain \
    --num_train_epochs 1 \
    --per_device_train_batch_size 16 \
    --per_device_eval_batch_size 4 \
    --gradient_accumulation_steps 8 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 2400 \
    --save_total_limit 1 \
    --learning_rate 2e-3 \
    --weight_decay 0. \
    --warmup_ratio 0.03 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --tf32 True \
    --model_max_length 2048 \
    --gradient_checkpointing True \
    --lazy_preprocess True \
    --report_to wandb
```
</details>


### Visual Instruction Tuning

1. Prepare data

Please download the annotation of our instruction tuning data [llava_instruct_158k.json](https://huggingface.co/datasets/liuhaotian/LLaVA-Instruct-150K/blob/main/llava_instruct_150k.json), and download the COCO train2017 images [here](https://cocodataset.org/#download).

2. Start training!

You may download our pretrained projectors in [Model Zoo](https://github.com/haotian-liu/LLaVA/blob/main/docs/MODEL_ZOO.md). It is not recommended to use legacy projectors, as they may be trained with a different version of the codebase, and if any option is off, the model will not function/train as we expected.

When we initially released our paper, we used a full 3-epoch schedule on the LLaVA-Instruct-158K dataset. The scripts are provided [here](https://github.com/haotian-liu/LLaVA/blob/main/scripts/finetune_full_schedule.sh).

In our later exploration, we introduced LLaVA-Lightning, as we find that a much faster 1-epoch schedule on LLaVA-Instruct-80K can achieve fast convergence and good performance. With LLaVA Lightning, we are able to train, validate, and release LLaVA-LLaMA-2 checkpoints preview on the same day as LLaMA-2 release. If you are interested to learn more about LLaVA Lightning, please continue to the following section.

### Lightning

LLaVA-Lightning can be trained on 8x A100 GPUs in just 3 hours, including both pretraining and finetuning. When using spot instances, it costs just ~$40.

For LLaVA Lightning, we create two distilled subset to ensure both a broad concept coverage, and the efficiency in training. Furthermore, we only perform instruction tuning for 1 epoch, in contrast to 3 epochs in the paper. We find such schedule is effective and can achieve fast convergence and good performance.

For pretraining, we create a concept-balanced subset of LAION-CC-SBU. It consists of 558K images.  Download data [here](https://huggingface.co/datasets/liuhaotian/LLaVA-Pretrain/tree/main).

For instruction tuning, we create a subset of LLaVA-Instruct-150K. It consists of 80K image-instruction pairs, consisting of 40K conversation and 40K complex reasoning data, with non-overlapping images. Download `llava_instruct_80k.json` [here](https://huggingface.co/datasets/liuhaotian/LLaVA-Instruct-150K/blob/main/llava_instruct_80k.json).

#### Hyperparameters

1. Pretraining ([script](https://github.com/haotian-liu/LLaVA/blob/main/scripts/pretrain.sh))

| Hyperparameter | Global Batch Size | Learning rate | Epochs | Max length | Weight decay |
| --- | ---: | ---: | ---: | ---: | ---: |
| LLaVA-Lightning | 128 | 2e-3 | 1 | 2048 | 0 |

2. Visual Instruction Tuning ([script](https://github.com/haotian-liu/LLaVA/blob/main/scripts/finetune.sh))

| Hyperparameter | Global Batch Size | Learning rate | Epochs | Max length | Weight decay |
| --- | ---: | ---: | ---: | ---: | ---: |
| LLaVA-Lightning | 128 | 2e-5 | 1 | 2048 | 0 |

#### LLaVA-MPT-7b
Thanks to LLaVA-Lightning, we are able to train a checkpoint based on MPT-7B-Chat on 8x A100 GPUs in just 3 hours, including both pretraining and finetuning.

**NOTE**: This is a research preview of the LLaVA-Lightning based on MPT-7B-chat checkpoint. The usage of the model should comply with MPT-7B-chat license and agreements.

1. Usage

You do not need to download our checkpoint, it will directly load from our Hugging Face model: [`liuhaotian/LLaVA-Lightning-MPT-7B-preview`](https://huggingface.co/liuhaotian/LLaVA-Lightning-MPT-7B-preview).

```Shell
python -m llava.serve.controller --host 0.0.0.0 --port 10000
python -m llava.serve.model_worker --host 0.0.0.0 --controller http://localhost:10000 --port 40000 --worker http://localhost:40000 --model-path liuhaotian/LLaVA-Lightning-MPT-7B-preview
python -m llava.serve.gradio_web_server --controller http://localhost:10000
```

2. Training

We use the same set of training dataset, and the hyperparameters as other *Lightning* checkpoints.

## Evaluation

### GPT-assisted Evaluation

Our GPT-assisted evaluation pipeline for multimodal modeling is provided for a comprehensive understanding of the capabilities of vision-language models.  Please see our paper for more details.

1. Generate LLaVA responses

```Shell
python model_vqa.py \
    --model-path ./checkpoints/LLaVA-13B-v0 \
    --question-file \
    playground/data/coco2014_val_qa_eval/qa90_questions.jsonl \
    --image-folder \
    /path/to/coco2014_val \
    --answers-file \
    /path/to/answer-file-our.jsonl
```

2. Evaluate the generated responses.  In our case, [`answer-file-ref.jsonl`](./playground/data/coco2014_val_qa_eval/qa90_gpt4_answer.jsonl) is the response generated by text-only GPT-4 (0314), with the context captions/boxes provided.

```Shell
OPENAI_API_KEY="sk-***********************************" python llava/eval/eval_gpt_review_visual.py \
    --question playground/data/coco2014_val_qa_eval/qa90_questions.jsonl \
    --context llava/eval/table/caps_boxes_coco2014_val_80.jsonl \
    --answer-list \
    /path/to/answer-file-ref.jsonl \
    /path/to/answer-file-our.jsonl \
    --rule llava/eval/table/rule.json \
    --output /path/to/review.json
```

3. Summarize the evaluation results

```Shell
python summarize_gpt_review.py
```

## ScienceQA

Please check out the documentation [here](https://github.com/haotian-liu/LLaVA/blob/main/docs/ScienceQA.md).

## Citation

If you find LLaVA useful for your research and applications, please cite using this BibTeX:
```bibtex

@misc{liu2023llava,
      title={Improved Baselines with Visual Instruction Tuning}, 
      author={Liu, Haotian and Li, Chunyuan and Li, Yuheng and Lee, Yong Jae},
      publisher={arXiv:2310.03744},
      year={2023},
}

@misc{liu2023llava,
      title={Visual Instruction Tuning}, 
      author={Liu, Haotian and Li, Chunyuan and Wu, Qingyang and Lee, Yong Jae},
      publisher={arXiv:2304.08485},
      year={2023},
}
```

## Acknowledgement

- [Vicuna](https://github.com/lm-sys/FastChat): the codebase we built upon, and our base model Vicuna-13B that has the amazing language capabilities!

## Related Projects

- [Instruction Tuning with GPT-4](https://github.com/Instruction-Tuning-with-GPT-4/GPT-4-LLM)
- [LLaVA-Med: Training a Large Language-and-Vision Assistant for Biomedicine in One Day](https://github.com/microsoft/LLaVA-Med)
- [Otter: In-Context Multi-Modal Instruction Tuning](https://github.com/Luodian/Otter)

For future project ideas, please check out:
- [SEEM: Segment Everything Everywhere All at Once](https://github.com/UX-Decoder/Segment-Everything-Everywhere-All-At-Once)
- [Grounded-Segment-Anything](https://github.com/IDEA-Research/Grounded-Segment-Anything) to detect, segment, and generate anything by marrying [Grounding DINO](https://github.com/IDEA-Research/GroundingDINO) and [Segment-Anything](https://github.com/facebookresearch/segment-anything).
