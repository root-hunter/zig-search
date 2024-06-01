<a name="readme-top"></a>

[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<br />
<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
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

_Below is an example of how you can instruct your audience on installing and setting up your app. This template doesn't rely on any external dependencies or services._

1. Clone the repo
   ```sh
   git clone https://github.com/root-hunter/zig-search
   ```
2. Build executable
   ```sh
   zig build-exe src/main.zig --name zig-search -O ReleaseSafe  --build-id=sha1 -static
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

```sh
   zig-search /start/path <search string>
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [ ] Multihreading
- [ ] Advance text search


<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[license-shield]: https://img.shields.io/github/license/othneildrew/Best-README-Template.svg?style=for-the-badge
[license-url]: https://github.com/root-hunter/zig-search/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/antonio-ricciardi-279118210