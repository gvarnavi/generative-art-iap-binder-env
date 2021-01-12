# Generative Art Workshop Binder Environment (IAP 2021)

This is the git repository of the generative art workshop binder environment,
taught by Jovana Andrejevic, Nina Andrejevic, and George Varnavides, in IAP 2021.
The actual notebooks are loaded using [nbgitpuller](https://github.com/jupyterhub/nbgitpuller)
from the [content repository](https://github.com/gvarnavi/generative-art-iap).

## Integrating the Wolfram Engine

[Binder](https://mybinder.org/) allows you to turn a _public_ repository with jupyter notebooks, 
into a fully-interactive collection of notebooks with executable environments.
With the release of the [free Wolfram Engine](https://www.wolfram.com/engine/), 
and its integration as a [jupyter kernel](https://github.com/WolframResearch/WolframLanguageForJupyter)
we can extend this functionality to the Wolfram Language.
Just click on the icon to launch the binder: 
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/gvarnavi/generative-art-iap-binder-env/main?urlpath=git-pull%3Frepo%3Dhttps%253A%252F%252Fgithub.com%252Fgvarnavi%252Fgenerative-art-iap%26urlpath%3Dtree%252Fgenerative-art-iap%252F%26branch%3Dmaster)

### Licensing
For this to work, we're using the [on-demand licensing](https://hub.docker.com/r/wolframresearch/wolframengine#activate-ondemand) feature available in v12.2.
