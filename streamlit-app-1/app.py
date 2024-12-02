import streamlit as st
import os

def main():
    myenv = os.getenv("MYENV")
    title = 'Hello, {}! '.format(myenv)
    st.header(title)

    st.write('Welcome to my simple app!')

if __name__ == '__main__':
    main()