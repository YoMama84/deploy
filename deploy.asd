#|
 This file is a part of cl-mixed
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#


(asdf:defsystem deploy
  :version "1.0.0"
  :license "Artistic"
  :author "Nicolas Hafner <shinmera@tymoon.eu>"
  :maintainer "Nicolas Hafner <shinmera@tymoon.eu>"
  :description "Tools to aid in the deployment of a fully standalone application."
  :homepage "https://Shinmera.github.io/deploy/"
  :bug-tracker "https://github.com/Shinmera/deploy/issues"
  :source-control (:git "https://github.com/Shinmera/deploy.git")
  :serial T
  :components ((:file "package")
               (:file "shared-library-extract")
               (:file "toolkit")
               (:file "library")
               (:file "hooks")
               (:file "deploy")
               (:file "darwin")
               (:file "documentation"))
  :depends-on (:cffi
               :uiop
               :str
               :documentation-utils
               :trivial-features))
