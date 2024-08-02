# godot-groq-moa
Mixture of Agents using Groq with Godot (not wrapper ,can export Web)

this is not  based langchain,however I think almost same behavior. 
## Web Demo (Can't use clipboard ,drop api key with json)
https://huggingface.co/spaces/Akjava/llm-moa

## Godot Version
I used Godot4.3r1 for my webexport,but it was developed under 4.2.2

python version - not my projects
https://github.com/skapadia3214/groq-moa

## Final Inference.
the paper seemds say refer all version(cycle 1 - last),but it would consume too much token.

## License
All the code are MIT 
### prompt
prompts are Apache2.0 
I'm not sure prompt license,but I make prompt based groq-moa version.
that why it relase under Apache2.0 

## models
I recommend use llama 3.1, because of tokens.

### gemma2-9b-it
sometime broken with other referece,stop using ref in code.
### groq-tools


## my opinion about moa
I feel need more bigger LLM.
main needs 405b ,agents need around 70b size

## TODO
I'll support ollama and Gemeni,chatgpt before next month.

characters,add move variant images or remove them depends on response.

## Citation

This project implements the Mixture-of-Agents architecture proposed in the following paper:

```
@article{wang2024mixture,
  title={Mixture-of-Agents Enhances Large Language Model Capabilities},
  author={Wang, Junlin and Wang, Jue and Athiwaratkun, Ben and Zhang, Ce and Zou, James},
  journal={arXiv preprint arXiv:2406.04692},
  year={2024}
}
```

For more information about the Mixture-of-Agents concept, please refer to the [original research paper](https://arxiv.org/abs/2406.04692) and the [Together AI blog post](https://www.together.ai/blog/together-moa).
