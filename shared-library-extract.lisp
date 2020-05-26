(in-package :cl-user)

(in-package :shared-library-extract)

(defvar *object-tool* "otool")
(defvar *cp* "cp")
(defvar *ln* "ln")
(defvar *copyable-library-paths* (list "/opt/local/lib"))
(defvar *install-name-tool* "install_name_tool")

(defun object-tool (path)
  (flet ((process-line (line) (first (str:split " " (str:trim line)))))
    (with-input-from-string (output (uiop:run-program (list *object-tool* "-L" path)
                                                      :output '(:string :stripped t)))
      (loop for line = (read-line output nil)
            while (not (null line))
            collect (process-line line)))))

(defun copy-library-p (library-path)
  (find-if (lambda (i) (str:containsp i library-path)) *copyable-library-paths*))

(defun symbolic-link (from to)
  (format t "Symbolic link ~a to ~a" from to)
  (unless (equal from to)
    (uiop:run-program (list *ln* "-sf" from to) :ignore-error-status t)))

(defun copy-file (from to)
  (format t "Copy file ~a to ~a~%" from to)
  (uiop:run-program (list *cp* from to) :ignore-error-status t))

(defun file-name (path)
  "Extract the file name from a file path."
  (car (last (str:split "/" path))))

(defun file-folder (full-file-path)
  "Return the containing folder path for a file"
  (subseq full-file-path 0
          (- (length full-file-path) 1
             (position #\/ (reverse full-file-path)))))

(defun library-versions (library-name)
  "Return variations of a library version up to a major version. For
  example, libxyz.1.0.dylib should return libxyz.1.dylib and
  libxyz.dylib"
  (let* ((split-library-name (str:split "." library-name))
         (suffix (last split-library-name))
         (split-library-name (butlast split-library-name)))
    (loop for sublist on (reverse split-library-name)
          collect (format nil "~{~a~^.~}" (append (reverse sublist) suffix)))))

(defun install-name (from to path)
  (uiop:run-program (list *install-name-tool* "-change"
                          from to path)))

(defun install-id (id path)
  (uiop:run-program (list *install-name-tool* "-id"
                          id path)))

(defun install-names (library)
  (format t "Install names for library ~a~%" library)
  (install-id (format nil "@loader_path/~a" (file-name library)) library)
  (loop for object in (object-tool library)
        if (copy-library-p object)
          do (install-name object (format nil "@loader_path/~a" (file-name object)) library)))

(defun library-dependency-tree (library-path)
  (let ((queue (object-tool library-path))
        (seen-libraries))
    (remove-duplicates
     (loop for library = (pop queue)
           while (not (null library))
           if (copy-library-p library)
             do (unless (find library seen-libraries :test #'equal)
                  (push library seen-libraries)
                  (setf queue (append queue (cddr (object-tool library))))
                  (format t "Process Library: ~a ~%Depends on:~a~%" library (cddr (object-tool library))))
           if (copy-library-p library)
             collect library)
     :test #'equal)))

(defun process-library (library-path &optional destination)
  "Copy library dependencies recursively, additionally make symlinks
to major versions for a given library."
  (let ((destination (if destination destination (file-folder library-path))))
    (format t "Library Path ~a, Destination ~a ~%" library-path destination)
    (mapcar (lambda (i) (symbolic-link library-path (format nil "~a/~a" destination i))) 
            (library-versions (file-name library-path)))
    (loop for library in (library-dependency-tree library-path)
          do (let ((destination-path (format nil "~a/~a" destination (file-name library))))
               (copy-file library destination-path)
               (mapcar (lambda (i) (symbolic-link destination-path (format nil "~a/~a" destination i))) 
                       (library-versions (file-name library)))
               (install-names destination-path)))))

(defun process-libraries (libraries destination)
  (mapcar (lambda (i) (process-library i destination)) libraries))
