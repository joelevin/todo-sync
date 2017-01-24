;;; test-org-interaction --- Unit tests for my org-interaction library

;;; Commentary:
;; Every library needs a test suite.

;;; Code:
(require 'ert)
(require 'org-interaction)

(defun oi-make-headline-from-text (text)
  "Create a headline from the Org-formatted TEXT."
  (let (org-mode-hook)
    (org-element-map (with-temp-buffer
                       (org-mode)
                       (insert text)
                       (org-element-parse-buffer))
        'headline #'identity nil t)))

(defun oi-concat-with-newlines (&rest args)
  "Concatenate ARGS with newlines in between."
  (mapconcat #'identity args "\n"))

(defun oi-make-drawer-text-from-plist (plist)
  "Create Org property drawer text with keys & values from PLIST."
  (let (k v retval)
    (push ":PROPERTIES:" retval)
    (while plist
      (setq k (pop plist) v (pop plist))
      (push (concat (upcase (symbol-name k)) ":"
                    (make-string (max 1 (- 10 (length (symbol-name k))))
                                 ? )
                    v)
            retval))
    (push ":END:" retval)
    (apply 'oi-concat-with-newlines (nreverse retval))))

(ert-deftest oi-insert-child ()
  "Does `oi-insert-child' insert children correctly?"
  (let* ((parent-id "1")
         (position 0)
         (new-hl-plist (list :title "this is the new headline"
                             :id "A"))
         (parent-text (oi-concat-with-newlines
                       "* TODO this is the parent headline"
                       ":PROPERTIES:"
                       ":ID:       1"
                       ":END:"))
         (expected-text (oi-concat-with-newlines
                         "* TODO this is the parent headline"
                         ":PROPERTIES:"
                         ":ID:       1"
                         ":END:"
                         "** TODO this is the new headline"
                         ":PROPERTIES:"
                         ":ID:       A"
                         ":END:"))
         (parent-hl (oi-make-headline-from-text parent-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         retval
         (*org-ast-list* (list (cons "tmp" parent-hl))))
    (setq retval (oi-insert-child parent-id position new-hl-plist)
          parent-hl (oi-get-headline-from-id parent-id *org-ast-list*))
    (should (equal (org-element-interpret-data parent-hl)
                   (org-element-interpret-data expected-hl)))
    (should (equal retval (plist-get new-hl-plist :id))))
  (let* ((parent-id "1")
         (position 0)
         (new-hl-plist (list :title "this is the new headline" :id "A"))
         (parent-text (oi-concat-with-newlines
                       "* TODO this is the parent headline"
                       ":PROPERTIES:"
                       ":ID:       1"
                       ":END:"
                       "this is the parent paragraph"
                       "** TODO this is the child headline"
                       "this is the child paragraph"))
         (expected-text (oi-concat-with-newlines
                         "* TODO this is the parent headline"
                         ":PROPERTIES:"
                         ":ID:       1"
                         ":END:"
                         "this is the parent paragraph"
                         "** TODO this is the new headline"
                         ":PROPERTIES:"
                         ":ID:       A"
                         ":END:"
                         "** TODO this is the child headline"
                         "this is the child paragraph"))
         (parent-hl (oi-make-headline-from-text parent-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         retval
         (*org-ast-list* (list (cons "tmp" parent-hl))))
    (setq retval (oi-insert-child parent-id position new-hl-plist)
          parent-hl (oi-get-headline-from-id parent-id *org-ast-list*))
    (should (equal (org-element-interpret-data parent-hl)
                   (org-element-interpret-data expected-hl)))
    (should (equal retval (plist-get new-hl-plist :id)))))

(ert-deftest oi-delete ()
  "Does `oi-delete' delete headlines correctly?"
  (let* ((id-to-delete "1")
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the remaining headline"
                   "** TODO this is the headline to delete"
                   ":PROPERTIES:"
                   ":ID:       1"
                   ":END:"))
         (expected-text "* TODO this is the remaining headline")
         (hl (oi-make-headline-from-text hl-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (oi-delete id-to-delete)
    (should (equal (org-element-interpret-data hl)
                   (org-element-interpret-data expected-hl)))))

(ert-deftest oi-update ()
  "Does `oi-update' update properties correctly?"
  (let* ((id-to-update "1")
         (new-plist (list :title "this is the new title"))
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the current headline"
                   ":PROPERTIES:"
                   ":ID:       1"
                   ":END:"))
         (expected-text (oi-concat-with-newlines
                         "* TODO this is the new title"
                         ":PROPERTIES:"
                         ":ID:       1"
                         ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (oi-update id-to-update new-plist)
    (should (equal (org-element-interpret-data hl)
                   (org-element-interpret-data expected-hl))))
  (let* ((id-to-update "1")
         (new-plist (list :paragraph "this is the new paragraph"))
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the current headline"
                   ":PROPERTIES:"
                   ":ID:       1"
                   ":END:"
                   "this is the current paragraph"))
         (expected-text (oi-concat-with-newlines
                         "* TODO this is the current headline"
                         ":PROPERTIES:"
                         ":ID:       1"
                         ":END:"
                         "this is the new paragraph"))
         (hl (oi-make-headline-from-text hl-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (oi-update id-to-update new-plist)
    (should (equal (org-element-interpret-data hl)
                   (org-element-interpret-data expected-hl))))
  (let* ((id-to-update "1")
         (new-plist (list :custom_id "A"))
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the current headline"
                   ":PROPERTIES:"
                   ":ID:       1"
                   ":END:"))
         (expected-text (oi-concat-with-newlines
                         "* TODO this is the current headline"
                         ":PROPERTIES:"
                         ":ID:       1"
                         ":CUSTOM_ID: A"
                         ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (expected-hl (oi-make-headline-from-text expected-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (oi-update id-to-update new-plist)
    (should (equal (org-element-interpret-data hl)
                   (org-element-interpret-data expected-hl)))))

(ert-deftest oi-move-to ()
  "Does `oi-move-to' move headlines correctly?"
  (let* ((child-id "A")
         (position 0)
         (new-parent-id "2")
         (old-parent-text (oi-concat-with-newlines
                           "* TODO this is the old parent headline"
                           "** TODO this is the child headline"
                           ":PROPERTIES:"
                           ":ID:       A"
                           ":END:"))
         (old-expected-text "* TODO this is the old parent headline")
         (new-parent-text (oi-concat-with-newlines
                           "* TODO this is the new parent headline"
                           ":PROPERTIES:"
                           ":ID:       2"
                           ":END:"))
         (new-expected-text (oi-concat-with-newlines
                             "* TODO this is the new parent headline"
                             ":PROPERTIES:"
                             ":ID:       2"
                             ":END:"
                             "** TODO this is the child headline"
                             ":PROPERTIES:"
                             ":ID:       A"
                             ":END:"))
         (old-parent-hl (oi-make-headline-from-text old-parent-text))
         (old-expected-hl (oi-make-headline-from-text old-expected-text))
         (new-parent-hl (oi-make-headline-from-text new-parent-text))
         (new-expected-hl (oi-make-headline-from-text new-expected-text))
         (*org-ast-list* (list (cons "old" old-parent-hl)
                               (cons "new" new-parent-hl))))
    (oi-move-to child-id position new-parent-id)
    (should (equal (org-element-interpret-data new-parent-hl)
                   (org-element-interpret-data new-expected-hl)))
    (should (equal (org-element-interpret-data old-parent-hl)
                   (org-element-interpret-data old-expected-hl)))))

(ert-deftest oi-get-all-headlines ()
  "Does `oi-get-all-headlines' pull everything correctly?"
  (let* ((field-list '(:ID))
         (expected-text "[{'id': None}]")
         (hl-text "* TODO this is the only headline")
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:id))
         (expected-text "[{'id': \"A\"}]")
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the only headline"
                   ":PROPERTIES:"
                   ":ID:       A"
                   ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:custom_id))
         (expected-text "[{'custom_id': \"A\"}]")
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the only headline"
                   ":PROPERTIES:"
                   ":CUSTOM_ID: A"
                   ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:paragraph))
         (expected-text "[{'paragraph': \"\"}]")
         (hl-text "* TODO this is the only headline")
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:title))
         (expected-text "[{'title': \"this is the only headline\"}]")
         (hl-text "* TODO this is the only headline")
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:id))
         (expected-text "[{'id': None}, {'id': \"A\"}, {'id': \"B\"}]")
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the root headline"
                   "** TODO this is the first headline"
                   ":PROPERTIES:"
                   ":ID:       A"
                   ":END:"
                   "** TODO this is the second headline"
                   ":PROPERTIES:"
                   ":ID:       B"
                   ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:id :parent))
         (expected-text (concat
                         "[{'id': \"A\", 'parent': None}, "
                         "{'id': \"B\", 'parent': \"A\"}]"))
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the parent headline"
                   ":PROPERTIES:"
                   ":ID:       A"
                   ":END:"
                   "** TODO this is the child headline"
                   ":PROPERTIES:"
                   ":ID:       B"
                   ":END:"))
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text)))
  (let* ((field-list '(:paragraph))
         (expected-text (concat
                         "[{'paragraph': \"A string with a"
                         "\\n"
                         "newline in it.\"}]"))
         (hl-text (oi-concat-with-newlines
                   "* TODO this is the headline"
                   "A string with a"
                   "newline in it."))
         (hl (oi-make-headline-from-text hl-text))
         (*org-ast-list* (list (cons "tmp" hl))))
    (should (equal (oi-get-all-headlines field-list)
                   expected-text))))

(provide 'test-org-interaction)
;;; test-org-interaction.el ends here
