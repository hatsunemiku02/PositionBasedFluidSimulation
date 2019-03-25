﻿#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <array>
#include"pbfsim.h"


PBF pbf(500000, 1.0, 500.0 / 500000, 1000.0);

static void updateFPS() 
{
    static DWORD s = GetTickCount64(), e;
    static int count = 0;
    count++;
    if (count == 100) 
    {
        e = GetTickCount64();
        std::cout << float((100000.0f) / (e - s)) << std::endl;
        count = 0;
        s = e;
    }
}

GLFWwindow* window;

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) 
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    
}


static void windowsize_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
    pbf.camera.setViewFrustum(glm::pi<float>() / 2, static_cast<float>(width) / static_cast<float>(height));
}

static void scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
{
    pbf.camera.moveForward(yoffset);
}

static void cursorposition_callback(GLFWwindow* window, double xpos,double ypos)
{
    static double x_prev = 0;
    static double y_prev = 0;
    double delta_x = xpos - x_prev;
    double delta_y = ypos - y_prev;
    if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_1)==GLFW_PRESS) {
        pbf.camera.rotateRight(-delta_x/500.0);
        pbf.camera.rotateUp(delta_y/500.0);
    }
    x_prev = xpos;
    y_prev = ypos;
}

void updateCamera()
{
    float speed = 0.1;
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
    {
        pbf.camera.moveUp(speed);
    }

    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
    {
        pbf.camera.moveUp(-speed);
    }

    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
    {
        pbf.camera.moveRight(-speed);
    }
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
    {
        pbf.camera.moveRight(speed);
    }

}

int main(void) 
{

    if (!glfwInit())
        exit(EXIT_FAILURE);

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_SAMPLES, 2);

    window = glfwCreateWindow(512, 512, "Window", NULL, NULL);
    if (!window) 
    {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    glfwSetKeyCallback(window, key_callback);
    glfwSetWindowSizeCallback(window, windowsize_callback);
    glfwSetScrollCallback(window, scroll_callback);
    glfwSetCursorPosCallback(window, cursorposition_callback);

    glfwMakeContextCurrent(window);

    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    const GLubyte* OpenGLVersion = glGetString(GL_VERSION);
    const GLubyte* OpenGLVender = glGetString(GL_VENDOR);
    std::cout << OpenGLVersion << std::endl;
    std::cout << OpenGLVender << std::endl;

    glfwSwapInterval(0);

    pbf.initialize();
    pbf.camera.moveForward(-10.0);
    pbf.camera.moveUp(1.0);

    while (!glfwWindowShouldClose(window)) 
    {
        updateCamera();
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        double timestep = 1 / 60.0;

        pbf.sim(timestep);

        pbf.render();

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwDestroyWindow(window);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}
