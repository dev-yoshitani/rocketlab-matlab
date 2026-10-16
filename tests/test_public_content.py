"""Exercise the public checker without using external or experimental data."""
from pathlib import Path
from contextlib import contextmanager
import importlib.util
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('checker',ROOT/'tools/check_public.py')
checker=importlib.util.module_from_spec(spec); spec.loader.exec_module(checker)


@contextmanager
def scratch():
    base=ROOT/'work/checker-tests'; base.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(dir=base) as folder:
        assert Path(folder).resolve().is_relative_to(base.resolve())
        yield Path(folder)


class ContentTests(unittest.TestCase):
    def test_accept_synthetic_text(self):
        with scratch() as p:
            (p/'example.csv').write_text('time,value\n0,10\n1,20\n',encoding='utf-8')
            self.assertFalse(checker.inspect(p)[1])

    def test_reject_personal_path(self):
        with scratch() as p:
            value='\\'.join(('C:','Users','example','private.csv'))
            (p/'example.txt').write_text(value,encoding='utf-8')
            self.assertTrue(checker.inspect(p)[1])

    def test_reject_token_shape(self):
        with scratch() as p:
            (p/'example.txt').write_text('ghp_'+'a'*36,encoding='utf-8')
            self.assertTrue(checker.inspect(p)[1])

    def test_reject_private_document(self):
        with scratch() as p:
            (p/'example.docx').write_bytes(b'fixture')
            self.assertTrue(checker.inspect(p)[1])

    def test_generated_cache_is_not_public(self):
        with scratch() as p:
            (p/'README.md').write_text('synthetic example',encoding='utf-8')
            (p/'cached-model.slxc').write_bytes(b'generated cache')
            files,errors=checker.inspect(p)
            self.assertEqual(len(files),1); self.assertFalse(errors)


if __name__=='__main__':
    unittest.main()
