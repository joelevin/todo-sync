import os
import io
import collections


def breadth_first_order(self):
    result, queue = [], collections.deque()
    result.append(self)
    if self.children:
        node = self.children[0]
        while node:
            result.append(node)
            if node.children:
                queue.append(node)
            node = node.next_sibling()
            if not node and queue:
                node = queue.popleft().children[0]
    return result


def prettify_tree(tree, limit_to_attrs):
    buf = io.StringIO()
    if tree:
        attrs_dict = {'id': tree.id}
        if limit_to_attrs:
            for attr in limit_to_attrs:
                if hasattr(tree, attr):
                    attrs_dict[attr] = getattr(tree, attr)
        else:
            attrs_dict.update(tree.export_attrs)
        buf.write(str(attrs_dict))
        for c in tree.children:
            for line in prettify_tree(c, limit_to_attrs).splitlines():
                buf.write("\n  ")
                buf.write(line)
    return buf.getvalue()


def ppt(tree, limit_to_attrs=None):
    print(prettify_tree(tree, limit_to_attrs))


def make_wrapped_fn(title, fn):
    def dry_run_wrapper(*args, **kwargs):
        print(title, *args, *kwargs.items(), sep="\n ", end="\n\n")
        return fn(*args, **kwargs)
    return dry_run_wrapper


def make_print_fn(title):
    def dry_run_fn(*args, **kwargs):
        print(title, *args, *kwargs.items(), sep="\n  ", end="\n\n")
    return dry_run_fn


def make_counting_print_fn(title, retval_prefix='NEW'):
    i = 0

    def dry_run_fn(*args, **kwargs):
        nonlocal i
        retval = {'id': retval_prefix + " " + str(i)}
        print('{} {}'.format(title, retval),
              *args, *kwargs.items(), sep="\n  ", end="\n\n")
        i += 1
        return retval

    return dry_run_fn


def basename_no_ext(path):
    return os.path.splitext(os.path.basename(path))[0]


def safe_int(thing):
    if thing is None:
        return None
    else:
        return int(thing)
