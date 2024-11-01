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

使用的是 `Ubuntu` 版本号：`24.04.1 LTS`，32 G 内存，16 核的 CPU，没有 GPU，这里我是在本地的服务器上建立了一台虚拟机

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

### 3 推理 - 直接通过脚本

直接通过 python 脚本来调用模型，而不是通过 api 的方式进行调用

```python
import os
from transformers import AutoTokenizer
from vllm import LLM, SamplingParams

# 设置环境变量
os.environ['VLLM_TARGET_DEVICE'] = 'cpu'

# 下载的模型权重文件目录
model_dir = '/root/modelspace/Qwen2.5-1.5B-Instruct'

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

### 4 推理 - 通过调用 api

#### 4.1 部署大模型 api 服务

##### 4.1.1 部署 api

不管是脚本客户端调用 api，还是 webui 的方式进行调用 api，首先要做的是部署运行大模型 api 服务

```shell
vllm serve /root/modelspace/Qwen2.5-1.5B-Instruct
  --served-model-name Qwen/Qwen2.5-1.5B-Instruct
  --port 8000
  --host 0.0.0.0
  --device cpu
  --disable-frontend-multiprocessing
```

---

**注意**：上面的命令中，重点关注下 `--disable-frontend-multiprocessing` 这个参数选项，如果不指定，客户端调用 api 的时候会报错。可能跟我使用的模型的参数大小有关系，如果是 0.5B，就不会报错

---

```python
INFO 11-01 01:16:06 engine.py:297] Added request
chat-027710c78bb6449cb547ea684c82e5c0.

ERROR 11-01 01:16:33 client.py:262] RuntimeError('Engine loop has died')
ERROR 11-01 01:16:33 client.py:262] Traceback (most recent call last):

ERROR 11-01 01:16:33 client.py:262]   File "/root/miniconda3/envs/
ravllm/lib/python3.10/site-packages/vllm-0.6.3.post2.dev76+g51c24c97.
cpu-py3.10-linux-x86_64.egg/vllm/engine/multiprocessing/client.py",
line 150, in run_heartbeat_loop

ERROR 11-01 01:16:33 client.py:262]     await self._check_success(
ERROR 11-01 01:16:33 client.py:262]   File "/root/miniconda3/envs/
ravllm/lib/python3.10/site-packages/vllm-0.6.3.post2.dev76+g51c24c97.
cpu-py3.10-linux-x86_64.egg/vllm/engine/multiprocessing/client.py",
line 326, in _check_success

ERROR 11-01 01:16:33 client.py:262]     raise response
ERROR 11-01 01:16:33 client.py:262] RuntimeError: Engine loop has died
CRITICAL 11-01 01:16:43 launcher.py:99] MQLLMEngine is already dead,
terminating server process

INFO:     127.0.0.1:42718 - "POST /v1/chat/completions HTTP/1.1"
                            500 Internal Server Error
INFO:     Shutting down
INFO:     Waiting for application shutdown.
INFO:     Application shutdown complete.
INFO:     Finished server process [124376]

(ravllm) root@local:~# /root/miniconda3/envs/ravllm/lib/python3.10/
multiprocessing/resource_tracker.py:224: UserWarning:
resource_tracker: There appear to be 1 leaked semaphore objects to
clean up at shutdown
  warnings.warn('resource_tracker: There appear to be %d '
```

🆘 🆘 🆘
**查阅了资料，目前还没有找出具体原因（网上的资料说什么的都有，都不能解决问题）**

🚀 正常启动服务后，运行如下：

```python
(ravllm) root@local:~# vllm serve /root/modelspace/Qwen2.5-1.5B-Instruct --served-model-name Qwen/Qwen2.5-1.5B-Instruct --port 8000 --host 0.0.0.0 --device cpu --disable-frontend-multiprocessing
INFO 11-01 01:33:42 importing.py:13] Triton not installed; certain GPU-related functions will not be available.
INFO 11-01 01:33:45 api_server.py:528] vLLM API server version 0.6.3.post2.dev76+g51c24c97
INFO 11-01 01:33:45 api_server.py:529] args: Namespace(subparser='serve', model_tag='/root/modelspace/Qwen2.5-1.5B-Instruct', config='', host='0.0.0.0', port=8000, uvicorn_log_level='info', allow_credentials=False, allowed_origins=['*'], allowed_methods=['*'], allowed_headers=['*'], api_key=None, lora_modules=None, prompt_adapters=None, chat_template=None, response_role='assistant', ssl_keyfile=None, ssl_certfile=None, ssl_ca_certs=None, ssl_cert_reqs=0, root_path=None, middleware=[], return_tokens_as_token_ids=False, disable_frontend_multiprocessing=True, enable_auto_tool_choice=False, tool_call_parser=None, tool_parser_plugin='', model='/root/modelspace/Qwen2.5-1.5B-Instruct', task='auto', tokenizer=None, skip_tokenizer_init=False, revision=None, code_revision=None, tokenizer_revision=None, tokenizer_mode='auto', trust_remote_code=False, download_dir=None, load_format='auto', config_format=<ConfigFormat.AUTO: 'auto'>, dtype='auto', kv_cache_dtype='auto', quantization_param_path=None, max_model_len=None, guided_decoding_backend='outlines', distributed_executor_backend=None, worker_use_ray=False, pipeline_parallel_size=1, tensor_parallel_size=1, max_parallel_loading_workers=None, ray_workers_use_nsight=False, block_size=16, enable_prefix_caching=False, disable_sliding_window=False, use_v2_block_manager=False, num_lookahead_slots=0, seed=0, swap_space=4, cpu_offload_gb=0, gpu_memory_utilization=0.9, num_gpu_blocks_override=None, max_num_batched_tokens=None, max_num_seqs=256, max_logprobs=20, disable_log_stats=False, quantization=None, rope_scaling=None, rope_theta=None, enforce_eager=False, max_context_len_to_capture=None, max_seq_len_to_capture=8192, disable_custom_all_reduce=False, tokenizer_pool_size=0, tokenizer_pool_type='ray', tokenizer_pool_extra_config=None, limit_mm_per_prompt=None, mm_processor_kwargs=None, enable_lora=False, max_loras=1, max_lora_rank=16, lora_extra_vocab_size=256, lora_dtype='auto', long_lora_scaling_factors=None, max_cpu_loras=None, fully_sharded_loras=False, enable_prompt_adapter=False, max_prompt_adapters=1, max_prompt_adapter_token=0, device='cpu', num_scheduler_steps=1, multi_step_stream_outputs=True, scheduler_delay_factor=0.0, enable_chunked_prefill=None, speculative_model=None, speculative_model_quantization=None, num_speculative_tokens=None, speculative_disable_mqa_scorer=False, speculative_draft_tensor_parallel_size=None, speculative_max_model_len=None, speculative_disable_by_batch_size=None, ngram_prompt_lookup_max=None, ngram_prompt_lookup_min=None, spec_decoding_acceptance_method='rejection_sampler', typical_acceptance_sampler_posterior_threshold=None, typical_acceptance_sampler_posterior_alpha=None, disable_logprobs_during_spec_decoding=None, model_loader_extra_config=None, ignore_patterns=[], preemption_mode=None, served_model_name=['Qwen/Qwen2.5-1.5B-Instruct'], qlora_adapter_name_or_path=None, otlp_traces_endpoint=None, collect_detailed_traces=None, disable_async_output_proc=False, override_neuron_config=None, scheduling_policy='fcfs', disable_log_requests=False, max_log_len=None, disable_fastapi_docs=False, dispatch_function=<function serve at 0x7602e53ec700>)
WARNING 11-01 01:33:52 arg_utils.py:1038] [DEPRECATED] Block manager v1 has been removed, and setting --use-v2-block-manager to True or False has no effect on vLLM behavior. Please remove --use-v2-block-manager in your engine argument. If your use case is not supported by SelfAttnBlockSpaceManager (i.e. block manager v2), please file an issue with detailed information.
WARNING 11-01 01:33:52 config.py:421] Async output processing is only supported for CUDA, TPU, XPU. Disabling it for other platforms.
INFO 11-01 01:33:52 llm_engine.py:240] Initializing an LLM engine (v0.6.3.post2.dev76+g51c24c97) with config: model='/root/modelspace/Qwen2.5-1.5B-Instruct', speculative_config=None, tokenizer='/root/modelspace/Qwen2.5-1.5B-Instruct', skip_tokenizer_init=False, tokenizer_mode=auto, revision=None, override_neuron_config=None, rope_scaling=None, rope_theta=None, tokenizer_revision=None, trust_remote_code=False, dtype=torch.bfloat16, max_seq_len=32768, download_dir=None, load_format=LoadFormat.AUTO, tensor_parallel_size=1, pipeline_parallel_size=1, disable_custom_all_reduce=False, quantization=None, enforce_eager=False, kv_cache_dtype=auto, quantization_param_path=None, device_config=cpu, decoding_config=DecodingConfig(guided_decoding_backend='outlines'), observability_config=ObservabilityConfig(otlp_traces_endpoint=None, collect_model_forward_time=False, collect_model_execute_time=False), seed=0, served_model_name=Qwen/Qwen2.5-1.5B-Instruct, num_scheduler_steps=1, chunked_prefill_enabled=False multi_step_stream_outputs=True, enable_prefix_caching=False, use_async_output_proc=False, use_cached_outputs=False, mm_processor_kwargs=None)
WARNING 11-01 01:33:53 cpu_executor.py:332] CUDA graph is not supported on CPU, fallback to the eager mode.
WARNING 11-01 01:33:53 cpu_executor.py:362] Environment variable VLLM_CPU_KVCACHE_SPACE (GB) for CPU backend is not set, using 4 by default.
INFO 11-01 01:33:56 importing.py:13] Triton not installed; certain GPU-related functions will not be available.
(VllmWorkerProcess pid=124634) INFO 11-01 01:33:59 selector.py:193] Cannot use _Backend.FLASH_ATTN backend on CPU.
(VllmWorkerProcess pid=124634) INFO 11-01 01:33:59 selector.py:131] Using Torch SDPA backend.
(VllmWorkerProcess pid=124634) INFO 11-01 01:33:59 multiproc_worker_utils.py:215] Worker ready; awaiting tasks
(VllmWorkerProcess pid=124634) INFO 11-01 01:33:59 selector.py:193] Cannot use _Backend.FLASH_ATTN backend on CPU.
(VllmWorkerProcess pid=124634) INFO 11-01 01:33:59 selector.py:131] Using Torch SDPA backend.
Loading safetensors checkpoint shards:   0% Completed | 0/1 [00:00<?, ?it/s]
Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00,  1.43it/s]
Loading safetensors checkpoint shards: 100% Completed | 1/1 [00:00<00:00,  1.43it/s]
(VllmWorkerProcess pid=124634)
INFO 11-01 01:34:00 cpu_executor.py:214] # CPU blocks: 9362
WARNING 11-01 01:34:01 serving_embedding.py:200] embedding_mode is False. Embedding API will not work.
INFO 11-01 01:34:01 launcher.py:19] Available routes are:
INFO 11-01 01:34:01 launcher.py:27] Route: /openapi.json, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /docs, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /docs/oauth2-redirect, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /redoc, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /health, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /tokenize, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /detokenize, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/models, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /version, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/chat/completions, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/completions, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/embeddings, Methods: POST
INFO:     Started server process [124595]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on socket ('0.0.0.0', 8000) (Press CTRL+C to quit)
INFO 11-01 01:34:11 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:34:21 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 0 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
```

##### 4.1.2 查看接口路由

启动后，可以看到暴露出的接口路由

```python
INFO 11-01 01:34:01 launcher.py:19] Available routes are:
INFO 11-01 01:34:01 launcher.py:27] Route: /openapi.json, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /docs, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /docs/oauth2-redirect, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /redoc, Methods: HEAD, GET
INFO 11-01 01:34:01 launcher.py:27] Route: /health, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /tokenize, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /detokenize, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/models, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /version, Methods: GET
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/chat/completions, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/completions, Methods: POST
INFO 11-01 01:34:01 launcher.py:27] Route: /v1/embeddings, Methods: POST
```

在浏览器中验证下一个接口，这里选择 `/v1/models`，在浏览器中输入完整的地址：`http://192.168.1.14:8000/v1/models`，输出结果如下

```json
{
  "object": "list",
  "data": [
    {
      "id": "Qwen/Qwen2.5-1.5B-Instruct",
      "object": "model",
      "created": 1730425425,
      "owned_by": "vllm",
      "root": "/root/modelspace/Qwen2.5-1.5B-Instruct",
      "parent": null,
      "max_model_len": 32768,
      "permission": [
        {
          "id": "modelperm-c05e0ff5d1494dbb9668f2b0bbed42c4",
          "object": "model_permission",
          "created": 1730425425,
          "allow_create_engine": false,
          "allow_sampling": true,
          "allow_logprobs": true,
          "allow_search_indices": false,
          "allow_view": true,
          "allow_fine_tuning": false,
          "organization": "*",
          "group": null,
          "is_blocking": false
        }
      ]
    }
  ]
}
```

#### 4.2 脚本客户端调用 api

python 脚本如下：

```python
from openai import OpenAI

openai_api_key = "EMPTY"
openai_api_base = "http://localhost:8000/v1"

client = OpenAI(
    api_key=openai_api_key,
    base_url=openai_api_base,
)

chat_response = client.chat.completions.create(
    model='Qwen/Qwen2.5-1.5B-Instruct',
    messages=[
        {
          "role": "system",
          "content": "You are Qwen. You are a helpful assistant.",
        },
        {
          "role": "user",
          "content": "详细讲解下股市运行的原理",
        },
    ],
    temperature=0.7,
    top_p=0.8,
    max_tokens=512,
    extra_body={
        "repetition_penalty": 1.05,
    },
    timeout=1800,
)

print("Chat response:", chat_response)
```

运行脚本后，查看下 api 服务端的日志

```python
INFO 11-01 01:50:17 logger.py:37] Received request
chat-2eea5af7a0f9416abdd7b625863de374: prompt: '<|im_start|
>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful
assistant.<|im_end|>\n<|im_start|>user\n详细讲解下股市运行的原理<|im_end|
>\n<|im_start|>assistant\n', params: SamplingParams(n=1,
presence_penalty=0.0, frequency_penalty=0.0, repetition_penalty=1.05,
temperature=0.7, top_p=0.8, top_k=-1, min_p=0.0, seed=None, stop=[],
stop_token_ids=[], include_stop_str_in_output=False, ignore_eos=False,
max_tokens=512, min_tokens=0, logprobs=None, prompt_logprobs=None,
skip_special_tokens=True, spaces_between_special_tokens=True,
truncate_prompt_tokens=None), guided_decoding=None, prompt_token_ids:
[151644, 8948, 198, 2610, 525, 1207, 16948, 11, 3465, 553, 54364,
14817, 13, 1446, 525, 264, 10950, 17847, 13, 151645, 198, 151644, 872,
198, 100700, 105250, 16872, 104908, 104001, 9370, 105318, 151645, 198,
151644, 77091, 198], lora_request: None, prompt_adapter_request: None.

INFO 11-01 01:50:17 async_llm_engine.py:207] Added request chat-2eea5af7a0f9416abdd7b625863de374.
INFO 11-01 01:50:21 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:50:31 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:50:41 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:50:51 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:01 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:11 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.0 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:19 metrics.py:363] Avg prompt throughput: 4.6 tokens/s, Avg generation throughput: 0.3 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:24 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.8 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:29 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.8 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:35 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.5 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:40 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.6 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
INFO 11-01 01:51:46 metrics.py:363] Avg prompt throughput: 0.0 tokens/s, Avg generation throughput: 0.7 tokens/s, Running: 1 reqs, Swapped: 0 reqs, Pending: 0 reqs, GPU KV cache usage: 0.0%, CPU KV cache usage: 0.0%.
```

可以看到服务端已经接收到请求，并开始逐步的进行处理，处理结束后，可以看到接口返回给客户端的结果，这里在客户端脚本中进行打印（这里等待的时间有点久，如果是 0.5B 就很快），返回结果如下：

```python
(ravllm) root@local:~/lmcode/25# python requ.py
Chat response: ChatCompletion
(id='chat-2eea5af7a0f9416abdd7b625863de374', choices=[Choice
(finish_reason='stop', index=0, logprobs=None,
message=ChatCompletionMessage(content='股市运行的原理主要包括以下几个方面：
\n\n1. 供需关系：股市是商品和服务的价格决定机制，股票价格由市场上的供求关系决定。当
市场上有更多的人想购买股票，而供不应求时，股票价格会上涨；反之，当市场上有更多的股票
供应，而需求小于供给时，股票价格会下跌。\n\n2. 利率变动：利率的上升通常会导致股票价
格下降，因为高利率可能会降低投资者的风险偏好，导致投资者更愿意将资金投资于债券等低风
险资产，而不是股票。相反，如果利率下降，股票价格通常会上涨，因为投资者可能更愿意将资
金投资于股票等高风险资产。\n\n3. 公司业绩：公司的盈利和业绩是影响股票价格的重要因
素。当一家公司盈利增长时，其股票价格通常会上涨，因为投资者认为该公司有更高的未来收益
潜力。相反，如果公司业绩下降，股票价格通常会下跌。\n\n4. 竞争与并购：在某些情况下，
竞争和并购也会影响股市的运行。例如，如果两家或多家公司合并，可能会导致市场上可供交易
的股票数量减少，从而推高股票价格。相反，如果一家公司被另一家收购，可能会导致该公司股
票价格下跌，因为投资者认为该公司失去了部分价值。\n\n5. 政策与法规：政府的政策和法规
也可能影响股市的运行。例如，政府可能会出台政策来刺激经济增长，这可能会导致股市上涨。
相反，如果政府出台了紧缩性的政策，可能会导致股市下跌。\n\n以上就是股市运行的基本原
理，当然，股市运行受到许多其他因素的影响，例如经济状况、国际形势、政治局势等等。',
refusal=None, role='assistant', audio=None, function_call=None,
tool_calls=[]), stop_reason=None)], created=1730425817, model='Qwen/
Qwen2.5-1.5B-Instruct', object='chat.completion', service_tier=None,
system_fingerprint=None, usage=CompletionUsage(completion_tokens=345,
prompt_tokens=36, total_tokens=381, completion_tokens_details=None,
prompt_tokens_details=None), prompt_logprobs=None)
```

到这里可以简单的庆祝下了，毕竟已经可以使用本地部署运行的大模型了。

#### 4.3 通过 WebUI 调用 api

这里使用了 gradio

```shell
pip install gradio
```

```python
import argparse
import gradio as gr
import requests
import json

def query_model(prompt):
    api_url = "http://127.0.0.1:8000/v1/chat/completions"
    headers = {"User-Agent": "vLLM Client"}
    pload = {
        "model": "Qwen/Qwen2.5-1.5B-Instruct",
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 128,
        "stream": True
    }

    try:
        # 发送请求，设置超时时间为 1800 秒
        response = requests.post(api_url, headers=headers, json=pload, stream=True, timeout=1800)

        result = ""
        # 处理流式返回的响应
        for chunk in response.iter_lines(chunk_size=8192, decode_unicode=False):
            if chunk:
                chunk_str = chunk.decode("utf-8")
                print(chunk_str)

                # 去除开头的 "data: " 部分，确保我们只处理 JSON 部分
                if chunk_str.startswith("data: "):
                    chunk_str = chunk_str[6:].strip()

                # 确保不处理 keep-alive 的心跳消息
                if chunk_str == "[DONE]":
                    break

                # 解析 JSON 数据
                try:
                    data = json.loads(chunk_str)
                    # 从响应中提取内容
                    if "choices" in data:
                        delta = data["choices"][0]["delta"]
                        if "content" in delta:
                            result += delta["content"]
                except json.JSONDecodeError:
                    print(f"无法解析的 JSON 数据：{chunk_str}")

        return result
    except requests.exceptions.Timeout:
        return "请求超时，请重试。"
    except Exception as e:
        return f"请求失败：{e}"

# 构建 Gradio UI
def build_demo():
    with gr.Blocks() as demo:
        gr.Markdown("# Qwen/Qwen2.5-1.5B-Instruct 模型交互界面")
        prompt = gr.Textbox(label="输入提示", placeholder="请输入您的问题或提示...")
        result = gr.Textbox(label="模型响应")

        # 修正 prompt.submit() 调用，只传递 Gradio 组件
        prompt.submit(query_model, inputs=prompt, outputs=result)
    return demo

# 主程序入口
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8001)
    args = parser.parse_args()

    demo = build_demo()
    demo.queue().launch(server_name=args.host, server_port=args.port, share=True)
```

然后运行服务，这里提醒，不能创建分享链接，如果想要创建分享链接，就按照下面的步骤进行操作即可。

```shell
(ravllm) root@local:~/lmcode/25# python ui.py
* Running on local URL:  http://0.0.0.0:8001

Could not create share link. Missing file: /root/miniconda3/envs/ravllm/lib/python3.10/site-packages/gradio/frpc_linux_amd64_v0.3.

Please check your internet connection. This can happen if your antivirus software blocks the download of this file. You can install manually by following these steps:

1. Download this file: https://cdn-media.huggingface.co/frpc-gradio-0.3/frpc_linux_amd64
2. Rename the downloaded file to: frpc_linux_amd64_v0.3
3. Move the file to this location: /root/miniconda3/envs/ravllm/lib/python3.10/site-packages/gradio
```

按照上面的步骤，下载移动 `frpc_linux_amd64`

```shell
cd ~
wget https://cdn-media.huggingface.co/frpc-gradio-0.3/frpc_linux_amd64
mv frpc_linux_amd64 frpc_linux_amd64_v0.3
mv frpc_linux_amd64_v0.3 /root/miniconda3/envs/ravllm/lib/python3.10/site-packages/gradio
```

然后重新启动服务，在浏览器中进行访问，可以看到以下界面，然后就可以进行交互了。

![webui.png](webui.png)

这里截取了处理过程中的一段日志，可以看到请求通过 `stream` 的方式，像管道中的流水一样

```python
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"role":"assistant","content":""},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"芯片"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"的"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"制作"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"原理"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"是一项"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"非常"},"logprobs":null,"finish_reason":null}]}
data: {"id":"chat-f434de356a7d4e42b5ac89ea4d8d9b91","object":"chat.completion.chunk","created":1730427228,"model":"Qwen/Qwen2.5-1.5B-Instruct","choices":[{"index":0,"delta":{"content":"复杂"},"logprobs":null,"finish_reason":null}]}
```

本地部署的这个大模型，还有些缺点，例如不能理解上下文。
如果部署是在有 GPU 显卡的服务器上，部署更快捷，模型推理更快。
