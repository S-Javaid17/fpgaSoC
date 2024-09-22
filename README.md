
# **[SoC with Video and I/O](./SoC%20Top)**

This project builds a custom System on Chip (SoC) implemented on the Nexys A7 development board (Artix-7 FPGA). The SoC incorporates both a Memory-Mapped I/O (MMIO) subsystem and a functional video output subsystem.

The MMIO subsystem is capable of managing up to 64 I/O cores, with flexible input and output configurations, making it useful for many applications.     
The video subsystem is responsible for rendering output directly to a VGA display, allowing for real-time video processing.

Much of this design is based on examples from the book *"FPGA Prototyping by SystemVerilog Examples"* by Pong P. Chu, which is a great reference for learning and prototyping.

****Refer to the "SoC Top" folder to navigate through the project***
## **Top-Level Diagram of the System**

![image](https://github.com/user-attachments/assets/35959464-0ea1-46a9-a355-f296e69e63ef)

**IP From Xilinx/AMD Are Highlighted in Grey**.

The SoC is implemented using the *MicroBlaze MicroController System (MCS)* from AMD.

## **Selected Example Demonstrations**
- [ADC](./SoC%20Top/MMIO%20Subsystem/ADC%20Core)
- [SPI](./SoC%20Top/MMIO%20Subsystem/SPI%20Core)
- [Pattern Generator + RGB to Grayscale](./SoC%20Top/Video%20Subsystem/RGB-to-Grayscale%20Core)
- [Sprite](./SoC%20Top/Video%20Subsystem/Ghost%20Sprite%20Core)
- [On-Screen Character Display](./SoC%20Top/Video%20Subsystem/On-Screen%20Display%20Core)

  
### **Exclusion of Drivers and Applications**

In this repository, the focus is primarily on the hardware design and implementation of the SoC. Drivers and applications, which form the software layer responsible for interacting with the hardware, are not included in this repository.  

To build the drivers and applications for this project, please refer to the book referenced above.

### Attribution of Work

In this project, many components have been built from examples in "FPGA Prototyping by SystemVerilog Examples" by Pong P. Chu. 

To distinguish between my original contributions and those adapted from the book, I’ve listed them below:

**Original Work**:

- Modified implementation of the SoC's MMIO and video subsystems
- Development of additional I/O cores, examples, drivers, and applications
- All video demonstrations are my own
- Optimization of the video subsystem, along with its drivers for the Nexys A7 (Artix-7 FPGA) board


**Adapted From Pong P. Chu’s Book**:

- Basic architecture and examples for integrating the SoC
- Initial video and MMIO subsystem structure, cores, and control logic
