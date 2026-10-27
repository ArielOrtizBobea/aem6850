---
license: cc-by-nc-4.0
task_categories:
- text-classification
language:
- en
tags:
- finance
size_categories:
- 1K<n<10K
---

## Label Interpretation
LABEL_2: Neutral  
LABEL_1: Hawkish  
LABEL_0: Dovish 


## Citation and Contact Information


### Cite
Please cite our paper if you use any code, data, or models.

```c
@inproceedings{shah-etal-2023-trillion,
    title = "Trillion Dollar Words: A New Financial Dataset, Task {\&} Market Analysis",
    author = "Shah, Agam  and
      Paturi, Suvan  and
      Chava, Sudheer",
    booktitle = "Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)",
    month = jul,
    year = "2023",
    address = "Toronto, Canada",
    publisher = "Association for Computational Linguistics",
    url = "https://aclanthology.org/2023.acl-long.368",
    doi = "10.18653/v1/2023.acl-long.368",
    pages = "6664--6679",
    abstract = "Monetary policy pronouncements by Federal Open Market Committee (FOMC) are a major driver of financial market returns. We construct the largest tokenized and annotated dataset of FOMC speeches, meeting minutes, and press conference transcripts in order to understand how monetary policy influences financial markets. In this study, we develop a novel task of hawkish-dovish classification and benchmark various pre-trained language models on the proposed dataset. Using the best-performing model (RoBERTa-large), we construct a measure of monetary policy stance for the FOMC document release days. To evaluate the constructed measure, we study its impact on the treasury market, stock market, and macroeconomic indicators. Our dataset, models, and code are publicly available on Huggingface and GitHub under CC BY-NC 4.0 license.",
}
```

### Contact Information

Please contact Agam Shah (ashah482[at]gatech[dot]edu) for any issues and questions.  
GitHub: [@shahagam4](https://github.com/shahagam4) 
Website: [https://shahagam4.github.io/](https://shahagam4.github.io/)