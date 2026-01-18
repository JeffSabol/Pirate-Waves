# Pirate Waves  
Godot 4.5 (4.3+ compatible)

**Pirate Waves** is a Godot-powered action game built on a reusable internal framework that provides menus, scene management, accessibility options, and production-ready tooling. The project is structured to support rapid iteration during development while remaining scalable for release builds.

This repository contains the game itself along with shared systems such as menus, loaders, save handling, and deployment utilities.

[Play on itch.io](https://b0rked.itch.io/pirate-waves)  

---

## Screenshots

<img width="1270" height="713" alt="Screenshot 1" src="https://github.com/user-attachments/assets/d9b86c8f-d607-4fdf-a25f-f4b452752498" />
<img width="1266" height="706" alt="Screenshot 2" src="https://github.com/user-attachments/assets/dfe2d36a-2294-4208-8286-049e645bbe47" />
<img width="1278" height="715" alt="Screenshot 3" src="https://github.com/user-attachments/assets/76803209-13ac-461b-b26e-b98a6ec76179" />
<img width="1270" height="708" alt="Screenshot 4" src="https://github.com/user-attachments/assets/facbd71f-ba68-418c-9afa-3095dce663a0" />
<img width="1278" height="714" alt="Screenshot 5" src="https://github.com/user-attachments/assets/20c2e11a-3f37-4c0c-8feb-dd10deec7f5d" />

---

## Objective

Deliver a polished, production-ready game experience with robust menus, accessibility features, clean scene transitions, and a scalable architecture suitable for future content and releases.

The underlying framework is game-agnostic (2D or 3D) and supports multiple target resolutions, from 640×360 up to 4K, while maintaining full keyboard, mouse, and gamepad support.

---

## Features

### Core Systems

The core systems power Pirate Waves’ UI, flow, and persistence:

- Main Menu  
- Options Menus  
- Pause Menu  
- Credits  
- Loading / Scene Transition System  
- Opening Scene  
- Persistent Settings  
- Config Interface  
- Extensible Overlay Menus  
- Keyboard / Mouse Support  
- Gamepad Support  
- UI Sound Controller  
- Background Music Controller  

---

### Game Systems

Systems used to manage gameplay flow and progression:

- Level Loading & Transitions  
- Level Progress Management  
- Win / Lose Conditions  
- Save / Resume Support  
- Tutorial & Messaging System  
- End Credits Flow  

---

### Tools & Extras

Supporting scripts and utilities used during development and release:

- Build & Packaging Scripts  
- itch.io Deployment (via `butler`)  
- Debug & Developer Tools  
- Scene Loader Utilities  

---

## Project Structure

