<a name="readme-top"></a>

[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- README Template by: https://github.com/othneildrew/Best-README-Template -->
<br />
<div align="center">
  <a href="https://github.com/root-hunter/zig-search/">
    <img src="images/zig-logo.png" alt="Logo">
  </a>

  <h3 align="center">zig-search</h3>

  <p align="center">
    High-performance search utility written entirely in Zig
    <br />
  </p>
</div>

<!-- ABOUT THE PROJECT -->
## About The Project
This is my first project written in Zig. I've been fascinated by Zig and its features, which offer a unique blend of performance, simplicity, and control. Zig-Search is a testament to the power and efficiency that Zig brings to the table, and it has been an exciting journey exploring what this language can do. I hope this tool showcases the potential of Zig and inspires others to explore it as well.

## Features
- 100% Zig implementation
- Fast and efficient directory scanning
- Recursive search in nested directories
- Simple command-line interface

<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Build Prerequisites

These are the prerequisites needed only to build the project, if you only want to use zig-search you can go to the <b>Usage</b> section
* [Install zig](https://ziglang.org/learn/getting-started/)

### Build 
1. Clone the repo
```sh
 git clone https://github.com/root-hunter/zig-search
```
2. Move to zig-search dir
```sh
cd zig-search
```
3. Build executable
```sh
make build-exe
```
   or
```sh
zig build-exe src/main.zig --name zig-search -O ReleaseSafe -static
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

```sh
   zig-search /start/path <search string>
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [ ] Help command
- [X] Multihreading
- [ ] Advance text search


<p align="right">(<a href="#readme-top">back to top</a>)</p>


## License
Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[license-shield]: https://img.shields.io/github/license/othneildrew/Best-README-Template.svg?style=for-the-badge
[license-url]: https://github.com/root-hunter/zig-search/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/antonio-ricciardi-279118210
