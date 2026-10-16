function h = code_hash(root)
files=dir(fullfile(root,'src','**','*.m'));
more=dir(fullfile(root,'*.m')); files=[files;more];
[~,order]=sort(string(fullfile({files.folder},{files.name}))); files=files(order);
tokens=strings(numel(files),1);
for k=1:numel(files)
 path=fullfile(files(k).folder,files(k).name);
 tokens(k)=erase(string(path),string(root))+":"+string(rocketlab.hash(path,true));
end
h=rocketlab.hash(join(tokens,newline));
end
