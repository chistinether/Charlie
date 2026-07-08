from django.contrib.auth import get_user_model
from rest_framework import serializers
from .models import StudentProfile

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    university = serializers.CharField(write_only=True)
    course = serializers.CharField(write_only=True)
    year_of_study = serializers.IntegerField(write_only=True)
    phone_number = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            "username",
            "email",
            "password",
            "first_name",
            "last_name",
            "university",
            "course",
            "year_of_study",
            "phone_number",
        ]

    def create(self, validated_data):
        university = validated_data.pop("university")
        course = validated_data.pop("course")
        year = validated_data.pop("year_of_study")
        phone = validated_data.pop("phone_number")

        password = validated_data.pop("password")

        user = User(**validated_data)
        user.set_password(password)
        user.save()

        StudentProfile.objects.create(
            user=user,
            university=university,
            course=course,
            year_of_study=year,
            phone_number=phone,
        )

        return user


class StudentProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudentProfile
        fields = [
            "university",
            "course",
            "year_of_study",
            "phone_number",
        ]


class UserSerializer(serializers.ModelSerializer):
    profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "profile",
        ]

    def get_profile(self, obj):
        profile = StudentProfile.objects.get(user=obj)
        return StudentProfileSerializer(profile).data
