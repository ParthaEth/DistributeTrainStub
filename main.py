import os
import torch
import distributed as dist
import torch.nn as nn
import torch.optim as optim
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from torchvision.datasets import ImageFolder
from torchvision.models import resnet50
import argparse
import tqdm




def get_dataloader(root_path, batch_size, rank, world_size):
    train_dataset = ImageFolder(root=root_path, transform=transforms.ToTensor())
    train_sampler = torch.utils.data.distributed.DistributedSampler(train_dataset, num_replicas=world_size, rank=rank)
    train_loader = DataLoader(train_dataset, batch_size=batch_size, sampler=train_sampler, num_workers=4)
    return train_loader

class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.resnet = resnet50(pretrained=False)
        in_features = self.resnet.fc.in_features
        self.resnet.fc = nn.Linear(in_features, 1000)  # Change 1000 to the number of classes in your dataset

    def forward(self, x):
        return self.resnet(x)

def train(args):
    dist.init()
    rank = dist.get_local_rank()
    global_rank = dist.get_global_rank()
    device = torch.device(rank)
    world_size = dist.get_world_size()
    print(f'Starting in machine {device} which is at rank {global_rank} of world size {world_size}')
    dist.print0(f'\n\nDistributing across {world_size} GPUs\n\n')

    model = SimpleNet()
    model = nn.parallel.DistributedDataParallel(model.to(device), device_ids=[rank,])

    optimizer = optim.SGD(model.parameters(), lr=args.lr)
    criterion = nn.CrossEntropyLoss()

    train_loader = get_dataloader(args.data_path, args.batch_size, global_rank, world_size)

    print(f'Starting train loop in device gpu:{global_rank}')
    for epoch in range(args.epochs):
        pbar = tqdm.tqdm(train_loader)
        for data, target in pbar:
            data, target = data.to(rank), target.to(rank)
            optimizer.zero_grad()
            output = model(data)
            loss = criterion(output, target)
            loss.backward()
            optimizer.step()
            pbar.set_description(f'CE loss: {loss.item():0.2f}')

    dist.cleanup()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Distributed DataParallel training script for ImageNet")
    parser.add_argument("--data_path", default='/is/cluster/fast/pghosh/datasets/celebA_HQ/fake_classification/',
                        type=str, help="Path to ImageNet data")
    parser.add_argument("--batch_size", type=int, default=64, help="Batch size for training")
    parser.add_argument("--lr", type=float, default=0.01, help="Learning rate")
    parser.add_argument("--epochs", type=int, default=5, help="Number of training epochs")
    args = parser.parse_args()

    train(args=args)
