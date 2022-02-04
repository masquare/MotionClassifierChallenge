# Motion Classifier Challenge

This demo was implemented as part of a challenge to classify walk/run activitties from smartphone accelerometer data.

Training data can be collected and predictions made in an iOS app.
The ML model is prepared in a Jupyter notebook.

## Repositoy contents
* MotionClassifierApp (iOS app): Here you can find the main part of the code in the classes ViewController.swift and MLUtil.swift.
* notebook (Jupyter Notebook): create, train and export the ML model
* sample: exemplarily recorded training data

## iOS App
The app can classify three types of movement: idle, walk & run.
To do so, the x,y,z values are read from the accelerometer at 20Hz and the class is predicted based on the last 200 value triples (= 10s * 20Hz).

## Procedure
1. Record training data in the app (20Hz accelerometer values with manual selection of class). The training data can then be exported as a CSV file.
2. Jupyter notebook: A supervised Problem is represented with the training data (values of the last 10s + assigned label). Then an ML model is trained with it. Finally, the model is exported for CoreML (iOS Machine Learning SDK).
3. The iPhone app loads the CoreML model from a private server at startup (so one can easily change the model) and then compiles it locally. Afterwards predictions are made -> at least 10s of recordings must have been made first. In the UI you can see the predicted class of the movement in the last 10s.

Please note that this is an MVP; I did not put massive effort into making it fail-safe, performant, etc. and did not collect excessive training samples to train the ML-model as stable as possible.
However, the classification works already quite well with little training data.

## Demo Video
https://user-images.githubusercontent.com/11543761/152486647-e56c9826-1bf9-4e41-b2c4-520da07087f3.mp4
