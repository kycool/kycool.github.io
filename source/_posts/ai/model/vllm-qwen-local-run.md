---
title: 大模型 | CPU 模式部署运行 Qwen 2.5 大模型
tags:
  - 大模型
categories:
  - - 人工智能
abbrlink: 51728
date: 2024-10-31 14:03:49
---

简单梳理下使用 vllm 通过 CPU 模式，部署运行 Qwen/Qwen2.5-1.5B-Instruct<!--more-->

### 1 环境准备

#### 1.1 操作系统

使用的是 `Ubuntu` 版本号：`24.04.1 LTS`

```python
# lsb_release -a

No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 24.04.1 LTS
Release:	24.04
Codename:	noble
```

#### 1.2 conda 安装

python 环境，使用的是 `Miniconda`
安装直接参考官方文档即可：https://docs.anaconda.com/miniconda/#quick-command-line-install

```python
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
```

然后激活 miniconda

```python
conda init bash

source /root/.bashrc
```

#### 1.3 conda 镜像设置

配置镜像是为了加速安装包，使用的是 `清华大学` 镜像
检查用户目录下是否存在 `.condarc`，如果不存在，则通过以下命令进行创建

```python
conda config --set show_channel_urls yes
```

然后打开 .condarc 文件，设置清华大学镜像

```python
show_channel_urls: true
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - defaults
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

保存后，通过 conda info 查看配置是否生效

```python
(base) root@local:~# conda info

     active environment : base
    active env location : /root/miniconda3
            shell level : 1
       user config file : /root/.condarc
 populated config files : /root/.condarc
          conda version : 24.7.1
    conda-build version : not installed
         python version : 3.12.4.final.0
                 solver : libmamba (default)
       virtual packages : __archspec=1=haswell
                          __conda=24.7.1=0
                          __glibc=2.39=0
                          __linux=6.8.0=0
                          __unix=0=0
       base environment : /root/miniconda3  (writable)
      conda av data dir : /root/miniconda3/etc/conda
  conda av metadata url : None
           channel URLs : https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/linux-64
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/noarch
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/linux-64
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/noarch
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/linux-64
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/noarch
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/linux-64
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/noarch
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/linux-64
                          https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/noarch
                          https://repo.anaconda.com/pkgs/main/linux-64
                          https://repo.anaconda.com/pkgs/main/noarch
                          https://repo.anaconda.com/pkgs/r/linux-64
                          https://repo.anaconda.com/pkgs/r/noarch
          package cache : /root/miniconda3/pkgs
                          /root/.conda/pkgs
       envs directories : /root/miniconda3/envs
                          /root/.conda/envs
               platform : linux-64
             user-agent : conda/24.7.1 requests/2.32.3 CPython/3.12.4 Linux/6.8.0-47-generic ubuntu/24.04.1 glibc/2.39 solver/libmamba conda-libmamba-solver/24.7.0 libmambapy/1.5.8 aau/0.4.4 c/. s/. e/.
                UID:GID : 0:0
             netrc file : None
           offline mode : False
```

#### 1.4 创建虚拟环境

创建环境名为 `ravllm` 的虚拟环境，使用的是 `Python 3.10`，然后激活

```python
conda create --name ravllM python=3.10 -y

conda activate ravllM
```

#### 1.5 安装 vllm

因为 vllm 默认支持 GPU，所以需要安装 CPU 版本，则需要自行编译安装

> 🔥 如果你有 GPU 显卡，建议直接使用 GPU 版本

```shell
pip install vllm
```

---

> 🔥 如果你没有 GPU 显卡，如果用 CPU 版本，则需要自行编译安装

```shell
# 安装 gcc 编译器
apt update  -y
apt install -y gcc-12 g++-12 libnuma-dev
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12
apt install -y cmake

# 克隆 vllm 仓库
mkdir ~/codespace && cd ~/codespace
git clone https://github.com/vllm-project/vllm.git vllm

# 安装 vllm 仓库所需的依赖
cd vllm
pip install wheel packaging ninja "setuptools>=49.4.0" numpy
pip install -v -r requirements-cpu.txt --extra-index-url https://download.pytorch.org/whl/cpu

# 打包安装
VLLM_TARGET_DEVICE=cpu python setup.py install
```

### 2 大模型下载

```shell
# 安装 git 环境
apt install -y git git-lfs
git lfs install

# 通过 git 下载大模型
mkdir -p ~/modelspace && cd ~/modelspace
git clone https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct Qwen2.5-1.5B-Instruct
```

注意：

- 如果从 https://huggingface.co 下载较慢，可以从国内的 https://www.modelscope.cn 进行下载
- 当然也可以通过 sdk 或者命令行的方式进行下载，可以自行参考官方文档

clone 完后，查看下大模型目录结构

```shell
(base) root@local:~/modelspace/Qwen2.5-1.5B-Instruct# ls -lah
total 2.9G
drwxr-xr-x 3 root root 4.0K Oct 30 06:05 .
drwxr-xr-x 5 root root 4.0K Oct 30 07:11 ..
-rw-r--r-- 1 root root  660 Oct 30 06:05 config.json
-rw-r--r-- 1 root root  242 Oct 30 06:05 generation_config.json
drwxr-xr-x 8 root root 4.0K Oct 30 06:07 .git
-rw-r--r-- 1 root root 1.5K Oct 30 06:05 .gitattributes
-rw-r--r-- 1 root root  12K Oct 30 06:05 LICENSE
-rw-r--r-- 1 root root 1.6M Oct 30 06:05 merges.txt
-rw-r--r-- 1 root root 2.9G Oct 30 06:05 model.safetensors
-rw-r--r-- 1 root root 4.9K Oct 30 06:05 README.md
-rw-r--r-- 1 root root 7.2K Oct 30 06:05 tokenizer_config.json
-rw-r--r-- 1 root root 6.8M Oct 30 06:05 tokenizer.json
-rw-r--r-- 1 root root 2.7M Oct 30 06:05 vocab.json
```

### 3 模型部署

#### 3.1 直接通过脚本

```python
import os
from transformers import AutoTokenizer
from vllm import LLM, SamplingParams

# 设置环境变量
os.environ['VLLM_TARGET_DEVICE'] = 'cpu'

# 模型 ID：我们下载的模型权重文件目录
model_dir = '/root/modelspace/Qwen2.5-1.5B-Instruct'

# Tokenizer 初始化
tokenizer = AutoTokenizer.from_pretrained(
    model_dir,
    local_files_only=True,
)

messages = [
    {'role': 'system', 'content': 'You are a helpful assistant.'},
    {'role': 'user', 'content': '跟我讲讲股市运行的逻辑'}
]
text = tokenizer.apply_chat_template(
    messages,
    tokenize=False,
    add_generation_prompt=True,
)

llm = LLM(
    model=model_dir,
    tensor_parallel_size=1,
    device='cpu',
)

sampling_params = SamplingParams(temperature=0.7, top_p=0.8, repetition_penalty=1.05, max_tokens=512)

outputs = llm.generate([text], sampling_params)

for output in outputs:
    prompt = output.prompt
    generated_text = output.outputs[0].text

    print(f'提示词：{prompt!r}, 大模型推理结果输出：{generated_text!r}')
```

然后在激活的 ravllm 环境下运行此脚本，在结果未输出之前，看下内存和 CPU 的状态
![cpu-status.png](cpu-status.png)

可以看到 16 核的 CPU 都在努力的工作。

推理结束，推理结果如下

```shell
(ravllm) root@local:~/lmcode/25# python local.py
INFO 10-31 08:51:52 importing.py:13] Triton not installed; certain
GPU-related functions will not be available.
WARNING 10-31 08:52:02 config.py:421] Async output processing is
only supported for CUDA, TPU, XPU. Disabling it for other platforms.

INFO 10-31 08:52:02 llm_engine.py:240] Initializing an LLM engine
(v0.6.3.post2.dev76+g51c24c97) with config: model='/root/modelspace/
Qwen2.5-1.5B-Instruct', speculative_config=None, tokenizer='/root/
modelspace/Qwen2.5-1.5B-Instruct', skip_tokenizer_init=False,
tokenizer_mode=auto, revision=None, override_neuron_config=None,
rope_scaling=None, rope_theta=None, tokenizer_revision=None,
trust_remote_code=False, dtype=torch.bfloat16, max_seq_len=32768,
download_dir=None, load_format=LoadFormat.AUTO,
tensor_parallel_size=1, pipeline_parallel_size=1,
disable_custom_all_reduce=False, quantization=None,
enforce_eager=False, kv_cache_dtype=auto,
quantization_param_path=None, device_config=cpu,
decoding_config=DecodingConfig(guided_decoding_backend='outlines'),
observability_config=ObservabilityConfig(otlp_traces_endpoint=None,
collect_model_forward_time=False, collect_model_execute_time=False),
seed=0, served_model_name=/root/modelspace/Qwen2.5-1.5B-Instruct,
num_scheduler_steps=1, chunked_prefill_enabled=False
multi_step_stream_outputs=True, enable_prefix_caching=False,
use_async_output_proc=False, use_cached_outputs=False,
mm_processor_kwargs=None)

WARNING 10-31 08:52:03 cpu_executor.py:332] CUDA graph is not
supported on CPU, fallback to the eager mode.

WARNING 10-31 08:52:03 cpu_executor.py:362] Environment variable
VLLM_CPU_KVCACHE_SPACE (GB) for CPU backend is not set, using 4 by
default.
INFO 10-31 08:52:03 selector.py:193]
Cannot use _Backend.FLASH_ATTN backend on CPU.
INFO 10-31 08:52:03 selector.py:131] Using Torch SDPA backend.
INFO 10-31 08:52:03 selector.py:193]
Cannot use _Backend.FLASH_ATTN backend on CPU.
INFO 10-31 08:52:03 selector.py:131] Using Torch SDPA backend.
Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00,  1.43it/s]
Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00,  1.43it/s]

INFO 10-31 08:52:05 cpu_executor.py:214] # CPU blocks: 9362
Processed prompts:   0%|                  | 0/1
[00:00<?, ?it/s, eProcessed prompts: 100%|█| 1/1
[07:28<00:00 44833s Processed prompts: 100%|█| 1/1
[07:28<00:00, 448.33s
Prompt提示词:
'<|im_start|>system\nYou are a helpful assistant.<|im_end|>\n
<|im_start|>user\n跟我讲讲股市运行的逻辑<|im_end|>\n
<|im_start|>assistant\n',
大模型推理输出: '股市是一个复杂的市场，其运行受到多种
因素的影响。以下是一些基本的逻辑：\n\n1. 供求关系：股票价格通常由供给和需求决定。
如果市场上有更多的人想要购买股票，而供应者却有限，那么股票的价格就会上升。反之，如
果供应量大于需求量，股票的价格就会下降。\n\n2. 公司基本面：公司的财务状况、盈利能
力、增长潜力等因素都会影响股票价格。投资者会关注公司的盈利预测、市盈率、股息支付等
指标。\n\n3. 市场情绪：市场情绪也会影响股票价格。例如，在经济衰退时期，投资者可能
会更加谨慎，从而导致股票价格下跌。而在经济繁荣时期，投资者可能会更加乐观，导致股票
价格上涨。\n\n4. 利率水平：利率水平也会影响股票价格。当利率上升时，投资者可能会更
愿意将资金投资于债券等固定收益产品，而不是股票，从而导致股票价格下跌。相反，当利率
下降时，股票价格可能会上涨。\n\n5. 外部事件：外部事件，如自然灾害、政策变化、地缘
政治冲突等，也可能对股市产生重大影响。\n\n需要注意的是，这些因素并不是独立的，它们
之间可能存在相互作用。此外，股市价格也会受到其他各种因素的影响，如公司业绩、新闻报
道、市场预期等。因此，投资者需要综合考虑各种因素，并结合自己的投资策略进行决策。'
```
